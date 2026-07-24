import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';

enum FriendshipStatus { pending, accepted, blocked }

@freezed
class FriendProfile with _$FriendProfile {
  const factory FriendProfile({
    required String userId,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) = _FriendProfile;
}

@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    required String id,
    required FriendProfile otherUser,
    required FriendshipStatus status,
    required bool isIncomingRequest,
  }) = _Friendship;
}

extension FriendshipStatusX on FriendshipStatus {
  static FriendshipStatus fromKey(String key) =>
      FriendshipStatus.values.firstWhere((e) => e.name == key, orElse: () => FriendshipStatus.pending);
}
