import 'dart:async';
import 'package:Openbook/models/post.dart';
import 'package:Openbook/models/posts_list.dart';
import 'package:Openbook/pages/home/pages/post/widgets/post_comment/post_comment.dart';
import 'package:Openbook/provider.dart';
import 'package:Openbook/services/httpie.dart';
import 'package:Openbook/services/toast.dart';
import 'package:Openbook/services/user.dart';
import 'package:Openbook/widgets/post/post.dart';
import 'package:Openbook/widgets/post/widgets/post-actions/widgets/post_action_comment.dart';
import 'package:Openbook/widgets/post/widgets/post-actions/widgets/post_action_react.dart';
import 'package:Openbook/widgets/post/widgets/post_comments/post_comments.dart';
import 'package:Openbook/widgets/theming/text.dart';
import 'package:flutter/material.dart';

class OBTrendingPosts extends StatefulWidget {
  final OBTrendingPostsController controller;
  final OnWantsToCommentPost onWantsToCommentPost;
  final OnWantsToReactToPost onWantsToReactToPost;
  final OnWantsToSeePostComments onWantsToSeePostComments;
  final OnWantsToSeeUserProfile onWantsToSeeUserProfile;

  OBTrendingPosts(
      {this.controller,
      this.onWantsToSeeUserProfile,
      this.onWantsToReactToPost,
      this.onWantsToCommentPost,
      this.onWantsToSeePostComments});

  @override
  State<StatefulWidget> createState() {
    return OBTrendingPostsState();
  }
}

class OBTrendingPostsState extends State<OBTrendingPosts> {
  UserService _userService;
  ToastService _toastService;

  List<Post> _posts;
  bool _needsBootstrap;

  StreamSubscription<PostsList> _getTrendingPostsSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) widget.controller.attach(this);
    _needsBootstrap = true;
    _posts = [];
  }

  @override
  void dispose() {
    super.dispose();
    if (_getTrendingPostsSubscription != null)
      _getTrendingPostsSubscription.cancel();
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
    return Column(
      children: [
        ListTile(
            title: OBText('Trending posts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
        Column(
            children: _posts.map((Post post) {
          return OBPost(
            post,
            onWantsToReactToPost: widget.onWantsToReactToPost,
            onWantsToCommentPost: widget.onWantsToCommentPost,
            onWantsToSeePostComments: widget.onWantsToSeePostComments,
            onWantsToSeeUserProfile: widget.onWantsToSeeUserProfile,
          );
        }).toList())
      ],
    );
  }

  void _bootstrap() {
    refresh();
  }

  Future<void> refresh() async {
    if (_getTrendingPostsSubscription != null)
      _getTrendingPostsSubscription.cancel();

    _getTrendingPostsSubscription = _userService
        .getTrendingPosts()
        .asStream()
        .listen((PostsList postsList) {
      _setPosts(postsList.posts);
    }, onError: (error) {
      if (error is HttpieConnectionRefusedError) {
        _toastService.error(
            message: 'No internet connection', context: context);
      } else {
        _toastService.error(message: 'Unknown error.', context: context);
        throw error;
      }
    });
  }

  void _setPosts(List<Post> posts) {
    setState(() {
      _posts = posts;
    });
  }
}

class OBTrendingPostsController {
  OBTrendingPostsState _state;

  void attach(OBTrendingPostsState state) {
    _state = state;
  }

  Future<void> refresh() {
    return _state.refresh();
  }
}
