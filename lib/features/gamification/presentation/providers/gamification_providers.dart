import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/gamification_repository_impl.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/repositories/gamification_repository.dart';

part 'gamification_providers.g.dart';

@Riverpod(keepAlive: true)
GamificationRepository gamificationRepository(Ref ref) {
  return GamificationRepositoryImpl(ref.watch(supabaseClientProvider), () => ref.read(currentUserProvider)?.id);
}

@riverpod
Future<List<Achievement>> achievements(Ref ref) async {
  final result = await ref.watch(gamificationRepositoryProvider).getAchievements();
  return result.match((failure) => throw failure, (list) => list);
}

@riverpod
Future<UserLevel?> myLevel(Ref ref) async {
  if (ref.watch(currentUserProvider) == null) return null;
  final result = await ref.watch(gamificationRepositoryProvider).getMyLevel();
  return result.match((failure) => throw failure, (level) => level);
}

@riverpod
Future<Streak?> myStreak(Ref ref) async {
  if (ref.watch(currentUserProvider) == null) return null;
  final result = await ref.watch(gamificationRepositoryProvider).getMyStreak();
  return result.match((failure) => throw failure, (streak) => streak);
}

@riverpod
Future<List<Challenge>> challenges(Ref ref) async {
  final result = await ref.watch(gamificationRepositoryProvider).getChallenges();
  return result.match((failure) => throw failure, (list) => list);
}
