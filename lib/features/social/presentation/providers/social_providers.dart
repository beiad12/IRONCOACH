import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/social_repository.dart';

part 'social_providers.g.dart';

@Riverpod(keepAlive: true)
SocialRepository socialRepository(Ref ref) {
  return SocialRepositoryImpl(ref.watch(supabaseClientProvider), () => ref.read(currentUserProvider)?.id);
}

@riverpod
Future<List<Friendship>> friendships(Ref ref) async {
  final result = await ref.watch(socialRepositoryProvider).getFriendships();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<List<Post>> friendFeed(Ref ref) async {
  final result = await ref.watch(socialRepositoryProvider).getFriendFeed();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<List<LeaderboardEntry>> leaderboard(Ref ref) async {
  final result = await ref.watch(socialRepositoryProvider).getLeaderboard();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<List<PostComment>> postComments(Ref ref, String postId) async {
  final result = await ref.watch(socialRepositoryProvider).getComments(postId);
  return result.match((failure) => throw failure, (list) => list);
}
