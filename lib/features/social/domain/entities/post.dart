import 'package:freezed_annotation/freezed_annotation.dart';

import 'friend.dart';

part 'post.freezed.dart';

enum PostType { workout, progressPhoto, achievement, text }

@freezed
class PostComment with _$PostComment {
  const factory PostComment({
    required String id,
    required FriendProfile author,
    required String body,
    required DateTime createdAt,
  }) = _PostComment;
}

@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required FriendProfile author,
    required PostType postType,
    required DateTime createdAt,
    String? caption,
    String? mediaUrl,
    String? workoutSessionId,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool isLikedByMe,
  }) = _Post;
}

extension PostTypeX on PostType {
  static PostType fromKey(String key) => switch (key) {
        'workout' => PostType.workout,
        'progress_photo' => PostType.progressPhoto,
        'achievement' => PostType.achievement,
        _ => PostType.text,
      };

  String get key => switch (this) {
        PostType.workout => 'workout',
        PostType.progressPhoto => 'progress_photo',
        PostType.achievement => 'achievement',
        PostType.text => 'text',
      };
}
