import 'package:Openbook/models/post.dart';
import 'package:Openbook/models/user.dart';
import 'package:Openbook/pages/home/pages/post/widgets/expanded_post_comment.dart';
import 'package:Openbook/pages/home/pages/profile/widgets/profile_card/profile_card.dart';
import 'package:Openbook/pages/home/pages/profile/widgets/profile_cover.dart';
import 'package:Openbook/pages/home/pages/profile/widgets/profile_nav_bar.dart';
import 'package:Openbook/pages/home/pages/timeline/widgets/timeline-posts.dart';
import 'package:Openbook/provider.dart';
import 'package:Openbook/services/httpie.dart';
import 'package:Openbook/services/toast.dart';
import 'package:Openbook/services/user.dart';
import 'package:Openbook/widgets/post/post.dart';
import 'package:Openbook/widgets/post/widgets/post-actions/widgets/post_action_comment.dart';
import 'package:Openbook/widgets/post/widgets/post-actions/widgets/post_action_react.dart';
import 'package:Openbook/widgets/post/widgets/post_comments/post_comments.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loadmore/loadmore_widget.dart';
import 'package:pigment/pigment.dart';

class OBProfilePage extends StatefulWidget {
  final OBProfilePageController controller;
  final User user;
  final OnWantsToCommentPost onWantsToCommentPost;
  final OnWantsToReactToPost onWantsToReactToPost;
  final OnWantsToSeePostComments onWantsToSeePostComments;
  final OnWantsToSeeUserProfile onWantsToSeeUserProfile;
  final OnWantsToEditUserProfile onWantsToEditUserProfile;

  OBProfilePage(this.user,
      {this.onWantsToSeeUserProfile,
      this.onWantsToSeePostComments,
      this.onWantsToReactToPost,
      this.onWantsToCommentPost,
      this.onWantsToEditUserProfile,
      this.controller});

  @override
  OBProfilePageState createState() {
    return OBProfilePageState();
  }
}

class OBProfilePageState extends State<OBProfilePage> {
  User _user;
  bool _needsBootstrap;
  bool _morePostsToLoad;
  List<Post> _posts;
  UserService _userService;
  ToastService _toastService;
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _needsBootstrap = true;
    _morePostsToLoad = false;
    _user = widget.user;
    _posts = [];
    if (widget.controller != null) widget.controller.attach(this);
  }

  @override
  Widget build(BuildContext context) {
    var openbookProvider = OpenbookProvider.of(context);
    _userService = openbookProvider.userService;
    _toastService = openbookProvider.toastService;

    if (_needsBootstrap) {
      _bootstrap();
      _needsBootstrap = false;
    }

    return CupertinoPageScaffold(
        backgroundColor: Color.fromARGB(0, 0, 0, 0),
        navigationBar: OBProfileNavBar(_user),
        child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: RefreshIndicator(
                  child: LoadMore(
                      whenEmptyLoad: false,
                      isFinish: !_morePostsToLoad,
                      delegate: OBHomePostsLoadMoreDelegate(),
                      child: ListView.builder(
                          controller: _scrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(0),
                          itemCount: _posts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                children: <Widget>[
                                  OBProfileCover(_user),
                                  OBProfileCard(_user,
                                      onWantsToEditUserProfile:
                                      widget.onWantsToEditUserProfile),
                                  Divider()
                                ],
                              );
                            }

                            int postIndex = index - 1;

                            var post = _posts[postIndex];

                            return OBPost(
                              post,
                              onWantsToReactToPost: widget
                                  .onWantsToReactToPost,
                              onWantsToCommentPost: widget
                                  .onWantsToCommentPost,
                              onWantsToSeePostComments:
                              widget.onWantsToSeePostComments,
                              onWantsToSeeUserProfile:
                              widget.onWantsToSeeUserProfile,
                            );
                          }),
                      onLoadMore: _loadMorePosts),
                  onRefresh: _refresh),
                )
              ],
            ),
          )
    );
  }

  void scrollToTop() {
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _bootstrap() async {
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      await Future.wait([_refreshUser(), _refreshPosts()]);
    } on HttpieConnectionRefusedError {
      _toastService.error(message: 'No internet connection', context: context);
    } catch (e) {
      _toastService.error(message: 'Unknown error.', context: context);
      rethrow;
    } finally {}
  }

  Future<void> _refreshUser() async {
    var user = await _userService.getUserWithUsername(_user.username);
    _setUser(user);
  }

  Future<void> _refreshPosts() async {
    _posts =
        (await _userService.getTimelinePosts(username: _user.username)).posts;
    _setPosts(_posts);
  }

  Future<bool> _loadMorePosts() async {
    var lastPost = _posts.last;
    var lastPostId = lastPost.id;
    try {
      var morePosts = (await _userService.getTimelinePosts(
              maxId: lastPostId, username: _user.username))
          .posts;

      if (morePosts.length == 0) {
        _setMorePostsToLoad(false);
      } else {
        setState(() {
          _posts.addAll(morePosts);
        });
      }
      return true;
    } on HttpieConnectionRefusedError catch (error) {
      _toastService.error(message: 'No internet connection', context: context);
    } catch (error) {
      _toastService.error(message: 'Unknown error.', context: context);
      rethrow;
    }

    return false;
  }

  void _setUser(User user) {
    setState(() {
      _user = user;
    });
  }

  void _setPosts(List<Post> posts) {
    setState(() {
      _posts = posts;
    });
  }

  void _setMorePostsToLoad(bool morePostsToLoad) {
    setState(() {
      _morePostsToLoad = morePostsToLoad;
    });
  }
}

class OBProfilePageController {
  OBProfilePageState _timelinePageState;

  void attach(OBProfilePageState profilePageState) {
    assert(profilePageState != null, 'Cannot attach to empty state');
    _timelinePageState = profilePageState;
  }

  void scrollToTop() {
    _timelinePageState.scrollToTop();
  }
}

typedef void OnWantsToEditUserProfile(User user);