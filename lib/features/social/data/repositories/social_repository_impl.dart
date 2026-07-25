import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  @override
  Future<Result<List<FriendProfile>>> searchUsers(String query) async {
    try {
      final rows = await _client
          .from(AppConstants.tableProfiles)
          .select('id, username, display_name, avatar_url')
          .ilike('username', '%$query%')
          .limit(20);
      return Right(List<Map<String, dynamic>>.from(rows as List)
          .map(_mapProfile)
          .toList());
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> sendFriendRequest(String targetUserId) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      await _client
          .from(AppConstants.tableFriendships)
          .insert({'requester_id': userId, 'addressee_id': targetUserId});
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> respondToFriendRequest(String friendshipId,
      {required bool accept}) async {
    try {
      if (accept) {
        await _client.from(AppConstants.tableFriendships).update({
          'status': 'accepted',
          'responded_at': DateTime.now().toIso8601String()
        }).eq('id', friendshipId);
      } else {
        await _client
            .from(AppConstants.tableFriendships)
            .delete()
            .eq('id', friendshipId);
      }
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> removeFriend(String friendshipId) async {
    try {
      await _client
          .from(AppConstants.tableFriendships)
          .delete()
          .eq('id', friendshipId);
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Friendship>>> getFriendships() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _client
          .from(AppConstants.tableFriendships)
          .select(
            'id, status, requester_id, addressee_id, '
            'requester:requester_id(id, username, display_name, avatar_url), '
            'addressee:addressee_id(id, username, display_name, avatar_url)',
          )
          .or('requester_id.eq.$userId,addressee_id.eq.$userId');

      return Right(
        List<Map<String, dynamic>>.from(rows as List).map((row) {
          final isRequester = row['requester_id'] == userId;
          final otherRaw = (isRequester ? row['addressee'] : row['requester'])
              as Map<String, dynamic>;
          return Friendship(
            id: row['id'] as String,
            otherUser: _mapProfile(otherRaw),
            status: FriendshipStatusX.fromKey(row['status'] as String),
            isIncomingRequest: !isRequester,
          );
        }).toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<Post>> createPost({
    required PostType postType,
    String? caption,
    String? mediaUrl,
    String? workoutSessionId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _client
          .from(AppConstants.tablePosts)
          .insert({
            'user_id': userId,
            'post_type': postType.key,
            'caption': caption,
            'media_url': mediaUrl,
            'workout_session_id': workoutSessionId,
          })
          .select(
              '*, profiles!posts_user_id_fkey(id, username, display_name, avatar_url)')
          .single();
      return Right(_mapPost(row, userId));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Post>>> getFriendFeed() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _client
          .from(AppConstants.tablePosts)
          .select(
            '*, profiles!posts_user_id_fkey(id, username, display_name, avatar_url), '
            'post_likes(user_id), post_comments(id)',
          )
          .order('created_at', ascending: false)
          .limit(50);
      return Right(List<Map<String, dynamic>>.from(rows as List)
          .map((r) => _mapPost(r, userId))
          .toList());
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleLike(String postId,
      {required bool isLiked}) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      if (isLiked) {
        await _client
            .from(AppConstants.tablePostLikes)
            .upsert({'post_id': postId, 'user_id': userId});
      } else {
        await _client
            .from(AppConstants.tablePostLikes)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      }
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<PostComment>>> getComments(String postId) async {
    try {
      final rows = await _client
          .from(AppConstants.tablePostComments)
          .select(
              '*, profiles!post_comments_user_id_fkey(id, username, display_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at');
      return Right(
        List<Map<String, dynamic>>.from(rows as List)
            .map(
              (row) => PostComment(
                id: row['id'] as String,
                author: _mapProfile(row['profiles'] as Map<String, dynamic>),
                body: row['body'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<PostComment>> addComment(String postId, String body) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _client
          .from(AppConstants.tablePostComments)
          .insert({'post_id': postId, 'user_id': userId, 'body': body})
          .select(
              '*, profiles!post_comments_user_id_fkey(id, username, display_name, avatar_url)')
          .single();
      return Right(
        PostComment(
          id: row['id'] as String,
          author: _mapProfile(row['profiles'] as Map<String, dynamic>),
          body: row['body'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<LeaderboardEntry>>> getLeaderboard(
      {bool friendsOnly = false}) async {
    try {
      final rows = await _client
          .from('leaderboard_view')
          .select()
          .order('total_xp', ascending: false)
          .limit(50);
      return Right(
        List<Map<String, dynamic>>.from(rows as List)
            .map(
              (row) => LeaderboardEntry(
                userId: row['user_id'] as String,
                username: row['username'] as String,
                displayName: row['display_name'] as String?,
                avatarUrl: row['avatar_url'] as String?,
                level: row['level'] as int,
                totalXp: row['total_xp'] as int,
                currentStreak: row['current_streak'] as int,
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  FriendProfile _mapProfile(Map<String, dynamic> row) {
    return FriendProfile(
      userId: row['id'] as String,
      username: row['username'] as String,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  Post _mapPost(Map<String, dynamic> row, String currentUserId) {
    final likes =
        List<Map<String, dynamic>>.from(row['post_likes'] as List? ?? []);
    final comments =
        List<Map<String, dynamic>>.from(row['post_comments'] as List? ?? []);
    return Post(
      id: row['id'] as String,
      author: _mapProfile(row['profiles'] as Map<String, dynamic>),
      postType: PostTypeX.fromKey(row['post_type'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      caption: row['caption'] as String?,
      mediaUrl: row['media_url'] as String?,
      workoutSessionId: row['workout_session_id'] as String?,
      likeCount: likes.length,
      commentCount: comments.length,
      isLikedByMe: likes.any((l) => l['user_id'] == currentUserId),
    );
  }
}
