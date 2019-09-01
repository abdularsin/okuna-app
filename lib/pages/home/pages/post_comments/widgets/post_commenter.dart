import 'package:Okuna/models/post.dart';
import 'package:Okuna/models/post_comment.dart';
import 'package:Okuna/pages/home/modals/create_post/widgets/remaining_post_characters.dart';
import 'package:Okuna/provider.dart';
import 'package:Okuna/services/draft.dart';
import 'package:Okuna/services/localization.dart';
import 'package:Okuna/services/text_account_autocompletion.dart';
import 'package:Okuna/services/toast.dart';
import 'package:Okuna/services/user.dart';
import 'package:Okuna/services/validation.dart';
import 'package:Okuna/widgets/alerts/alert.dart';
import 'package:Okuna/widgets/avatars/logged_in_user_avatar.dart';
import 'package:Okuna/widgets/avatars/avatar.dart';
import 'package:Okuna/widgets/buttons/button.dart';
import 'package:Okuna/widgets/fields/text_form_field.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:Okuna/services/httpie.dart';

class OBPostCommenter extends StatefulWidget {
  final Post post;
  final PostComment postComment;
  final bool autofocus;
  final FocusNode commentTextFieldFocusNode;
  final ValueChanged<PostComment> onPostCommentCreated;
  final VoidCallback onPostCommentWillBeCreated;
  final OBPostCommenterController controller;
  final ValueChanged<String> onWantsToSearchAccount;
  final VoidCallback onFinishedSearchingAccount;

  OBPostCommenter(this.post,
      {this.postComment,
      this.autofocus = false,
      this.controller,
      this.onWantsToSearchAccount,
      this.commentTextFieldFocusNode,
      this.onPostCommentCreated,
      this.onPostCommentWillBeCreated,
      this.onFinishedSearchingAccount});

  @override
  State<StatefulWidget> createState() {
    return OBPostCommenterState();
  }
}

class OBPostCommenterState extends State<OBPostCommenter> {
  TextEditingController _textController;
  bool _commentInProgress;
  bool _formWasSubmitted;
  bool _needsBootstrap;
  bool _isSearchingAccount;

  int _charactersCount;
  bool _isMultiline;

  int _postId;
  int _commentId;

  UserService _userService;
  ToastService _toastService;
  ValidationService _validationService;
  LocalizationService _localizationService;
  TextAccountAutocompletionService _textAccountAutocompletionService;
  DraftService _draftService;

  CancelableOperation _submitFormOperation;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _commentInProgress = false;
    _formWasSubmitted = false;
    _needsBootstrap = true;
    _charactersCount = 0;
    _isMultiline = false;
    _isSearchingAccount = false;
    _textController.addListener(_onPostCommentChanged);
    _postId = widget.post.id;
    if (widget.postComment != null) _commentId = widget.postComment.id;

    if (widget.controller != null) widget.controller.attach(this);
  }

  @override
  void dispose() {
    super.dispose();
    if (_submitFormOperation != null) _submitFormOperation.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_needsBootstrap) {
      var provider = OpenbookProvider.of(context);
      _userService = provider.userService;
      _toastService = provider.toastService;
      _validationService = provider.validationService;
      _localizationService = provider.localizationService;
      _textAccountAutocompletionService =
          provider.textAccountAutocompletionService;
      _draftService = provider.draftService;
      _textController.text = _draftService.getCommentDraft(_postId, _commentId);
      _needsBootstrap = false;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 20.0,
          ),
          Column(
            children: <Widget>[
              OBLoggedInUserAvatar(
                size: OBAvatarSize.medium,
              ),
              _isMultiline
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: OBRemainingPostCharacters(
                        maxCharacters:
                            ValidationService.POST_COMMENT_MAX_LENGTH,
                        currentCharacters: _charactersCount,
                      ),
                    )
                  : const SizedBox()
            ],
          ),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
            child: OBAlert(
              padding: const EdgeInsets.all(0),
              child: Form(
                  key: _formKey,
                  child: LayoutBuilder(builder: (context, size) {
                    TextStyle style = TextStyle(
                        fontSize: 14.0, fontFamilyFallback: ['NunitoSans']);
                    TextSpan text =
                        new TextSpan(text: _textController.text, style: style);

                    TextPainter tp = new TextPainter(
                      text: text,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                    );
                    tp.layout(maxWidth: size.maxWidth);

                    int lines =
                        (tp.size.height / tp.preferredLineHeight).ceil();

                    _isMultiline = lines > 3;

                    int maxLines = 5;

                    return _buildTextFormField(
                        lines < maxLines ? null : maxLines, style);
                  })),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 20.0, left: 10.0),
            child: OBButton(
              isLoading: _commentInProgress,
              size: OBButtonSize.small,
              onPressed: _submitForm,
              child:
                  Text(_localizationService.trans('post__commenter_post_text')),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextFormField(int maxLines, TextStyle style) {
    EdgeInsetsGeometry inputContentPadding =
        EdgeInsets.symmetric(vertical: 8.0, horizontal: 10);

    bool autofocus = widget.autofocus;
    FocusNode focusNode = widget.commentTextFieldFocusNode ?? null;

    return OBTextFormField(
      controller: _textController,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: maxLines,
      style: style,
      decoration: InputDecoration(
        hintText: _localizationService.trans('post__commenter_write_something'),
        contentPadding: inputContentPadding,
      ),
      hasBorder: false,
      autofocus: autofocus,
      autocorrect: true,
      validator: (String comment) {
        if (!_formWasSubmitted) return null;
        return _validationService.validatePostComment(_textController.text);
      },
    );
  }

  void _submitForm() async {
    if (_submitFormOperation != null) _submitFormOperation.cancel();
    _setFormWasSubmitted(true);

    bool formIsValid = _validateForm();

    if (!formIsValid) return;

    _setCommentInProgress(true);
    try {
      await (widget.onPostCommentWillBeCreated != null
          ? widget.onPostCommentWillBeCreated()
          : Future.value());
      String commentText = _textController.text;
      if (widget.postComment != null) {
        _submitFormOperation = CancelableOperation.fromFuture(
            _userService.replyPostComment(
                text: commentText,
                post: widget.post,
                postComment: widget.postComment));
      } else {
        _submitFormOperation = CancelableOperation.fromFuture(
            _userService.commentPost(text: commentText, post: widget.post));
      }

      PostComment createdPostComment = await _submitFormOperation.value;
      if (createdPostComment.parentComment == null)
        widget.post.incrementCommentsCount();
      _textController.clear();
      _setFormWasSubmitted(false);
      _validateForm();
      _setCommentInProgress(false);
      if (widget.onPostCommentCreated != null)
        widget.onPostCommentCreated(createdPostComment);
    } catch (error) {
      _onError(error);
    } finally {
      _submitFormOperation = null;
      _draftService.removeCommentDraft(_postId, _commentId);
      _setCommentInProgress(false);
    }
  }

  void _onPostCommentChanged() {
    int charactersCount = _textController.text.length;
    _setCharactersCount(charactersCount);
    _checkAutocomplete();
    _draftService.setCommentDraft(_textController.text, _postId, _commentId);
    if (charactersCount == 0) _setFormWasSubmitted(false);
    if (!_formWasSubmitted) return;
    _validateForm();
  }

  bool _validateForm() {
    return _formKey.currentState.validate();
  }

  void _autocompleteFoundAccountUsername(String foundAccountUsername) {
    if (!_isSearchingAccount) {
      debugLog(
          'Tried to autocomplete found account username but was not searching account');
      return;
    }

    debugLog('Autocompleting with username:$foundAccountUsername');
    setState(() {
      _textController.text =
          _textAccountAutocompletionService.autocompleteTextWithUsername(
              _textController.text, foundAccountUsername);
      _textController.selection =
          TextSelection.collapsed(offset: _textController.text.length);
    });
  }

  void _onError(error) async {
    if (error is HttpieConnectionRefusedError) {
      _toastService.error(
          message: error.toHumanReadableMessage(), context: context);
    } else if (error is HttpieRequestError) {
      String errorMessage = await error.toHumanReadableMessage();
      _toastService.error(message: errorMessage, context: context);
    } else {
      _toastService.error(
          message: _localizationService.trans('error__unknown_error'),
          context: context);
      throw error;
    }
  }

  void _checkAutocomplete() {
    TextAccountAutocompletionResult result = _textAccountAutocompletionService
        .checkTextForAutocompletion(_textController);

    if (result.isAutocompleting) {
      debugLog('Wants to search account with searchQuery:' +
          result.autocompleteQuery);
      _setIsSearchingAccount(true);
      if (widget.onWantsToSearchAccount != null) {
        widget.onWantsToSearchAccount(result.autocompleteQuery);
      }
    } else if (_isSearchingAccount) {
      debugLog('Finished searching account');
      if (widget.onFinishedSearchingAccount != null)
        widget.onFinishedSearchingAccount();
      _setIsSearchingAccount(false);
    }
  }

  void _setCommentInProgress(bool commentInProgress) {
    setState(() {
      _commentInProgress = commentInProgress;
    });
  }

  void _setIsSearchingAccount(bool isSearchingAccount) {
    setState(() {
      _isSearchingAccount = isSearchingAccount;
    });
  }

  void _setFormWasSubmitted(bool formWasSubmitted) {
    setState(() {
      _formWasSubmitted = formWasSubmitted;
    });
  }

  void _setCharactersCount(int charactersCount) {
    setState(() {
      _charactersCount = charactersCount;
    });
  }

  void debugLog(String log) {
    debugPrint('OBPostCommenter:$log');
  }
}

class OBPostCommenterController {
  OBPostCommenterState _state;

  void attach(OBPostCommenterState state) {
    _state = state;
  }

  void autocompleteFoundAccountUsername(String foundAccountUsername) {
    _state._autocompleteFoundAccountUsername(foundAccountUsername);
  }
}
