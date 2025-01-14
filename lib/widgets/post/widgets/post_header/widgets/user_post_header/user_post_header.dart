import 'package:Okuna/models/badge.dart';
import 'package:Okuna/models/post.dart';
import 'package:Okuna/models/user.dart';
import 'package:Okuna/pages/home/bottom_sheets/post_actions.dart';
import 'package:Okuna/provider.dart';
import 'package:Okuna/widgets/avatars/avatar.dart';
import 'package:Okuna/widgets/icon.dart';
import 'package:Okuna/widgets/post/widgets/post_header/widgets/user_post_header/widgets/post_creator_identifier.dart';
import 'package:Okuna/widgets/theming/text.dart';
import 'package:Okuna/widgets/theming/secondary_text.dart';
import 'package:Okuna/widgets/user_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OBUserPostHeader extends StatelessWidget {
  final Post _post;
  final OnPostDeleted onPostDeleted;
  final ValueChanged<Post> onPostReported;
  final bool hasActions;

  const OBUserPostHeader(this._post,
      {Key key,
      @required this.onPostDeleted,
      this.onPostReported,
      this.hasActions = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var openbookProvider = OpenbookProvider.of(context);
    var navigationService = openbookProvider.navigationService;
    var bottomSheetService = openbookProvider.bottomSheetService;
    var utilsService = openbookProvider.utilsService;
    var localizationService = openbookProvider.localizationService;

    if (_post.creator == null) return const SizedBox();

    return ListTile(
      leading: StreamBuilder(
          stream: _post.creator.updateSubject,
          initialData: _post.creator,
          builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
            User postCreator = snapshot.data;

            if (!postCreator.hasProfileAvatar()) return const SizedBox();

            return OBAvatar(
              onPressed: () {
                navigationService.navigateToUserProfile(
                    user: postCreator, context: context);
              },
              size: OBAvatarSize.medium,
              avatarUrl: postCreator.getProfileAvatar(),
            );
          }),
      trailing: hasActions
          ? IconButton(
              icon: const OBIcon(OBIcons.moreVertical),
              onPressed: () {
                bottomSheetService.showPostActions(
                    context: context,
                    post: _post,
                    onPostDeleted: onPostDeleted,
                    onPostReported: onPostReported);
              })
          : null,
      title: OBPostCreatorIdentifier(
        post: _post,
        onUsernamePressed: () {
          navigationService.navigateToUserProfile(
              user: _post.creator, context: context);
        },
      ),
      subtitle: _post.created != null
          ? OBSecondaryText(
              utilsService.timeAgo(_post.created, localizationService),
              style: TextStyle(fontSize: 12.0),
            )
          : const SizedBox(),
    );
  }
}
