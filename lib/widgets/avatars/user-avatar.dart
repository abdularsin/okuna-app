import 'package:flutter/material.dart';

enum UserAvatarSize { small, medium }

class UserAvatar extends StatelessWidget {
  final ImageProvider avatarImage;
  final UserAvatarSize size;
  final VoidCallback onPressed;

  static const double AVATAR_SIZE_SMALL = 30.0;
  static const double AVATAR_SIZE_MEDIUM = 40.0;
  static const ImageProvider DEFAULT_AVATAR =
  AssetImage('assets/images/avatar.png');

  UserAvatar({this.avatarImage = DEFAULT_AVATAR,
    this.size = UserAvatarSize.small,
    this.onPressed});

  @override
  Widget build(BuildContext context) {
    double avatarSize;

    UserAvatarSize finalSize = size ?? UserAvatarSize.small;

    switch (finalSize) {
      case UserAvatarSize.small:
        avatarSize = AVATAR_SIZE_SMALL;
        break;
      case UserAvatarSize.medium:
        avatarSize = AVATAR_SIZE_MEDIUM;
        break;
    }

    // Stupid dart when no argument was passed to constructor takes it as
    // literal null value passed instead of none. Skipping the default value
    // specified.
    var finalAvatarImage = avatarImage ?? DEFAULT_AVATAR;

    double avatarBorderRadius = 10.0;

    var avatar = Container(
      decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(avatarBorderRadius)),
      height: avatarSize,
      width: avatarSize,
      child: Container(
        child: ClipRRect(
            borderRadius: BorderRadius.circular(avatarBorderRadius),
            child: Container(
              child: null,
              decoration: BoxDecoration(
                  image:
                  DecorationImage(image:finalAvatarImage, fit: BoxFit.cover)),
            )),
      ),
    );

    if (onPressed == null) return avatar;

    return GestureDetector(
      child: avatar,
      onTap: onPressed,
    );
  }
}
