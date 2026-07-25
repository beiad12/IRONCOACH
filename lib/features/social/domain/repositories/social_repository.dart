import '../../../../core/utils/result.dart';
import '../entities/friend.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/post.dart';

abstract interface class SocialRepository {
  Future<Result<List<FriendProfile>>> searchUsers(String query);

  Future<Result<void>> sendFriendRequest(String targetUserId);

  Future<Result<void>> respondToFriendRequest(String friendshipId,
      {required bool accept});

  Future<Result<void>> removeFriend(String friendshipId);

  Future<Result<List<Friendship>>> getFriendships();

  Future<Result<Post>> createPost({
    required PostType postType,
    String? caption,
    String? mediaUrl,
    String? workoutSessionId,
  });

  Future<Result<List<Post>>> getFriendFeed();

  Future<Result<void>> toggleLike(String postId, {required bool isLiked});

  Future<Result<List<PostComment>>> getComments(String postId);

  Future<Result<PostComment>> addComment(String postId, String body);

  Future<Result<List<LeaderboardEntry>>> getLeaderboard(
      {bool friendsOnly = false});
}
