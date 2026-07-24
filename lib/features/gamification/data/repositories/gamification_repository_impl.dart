import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  @override
  Future<Result<List<Achievement>>> getAchievements() async {
    final userId = _currentUserId();
    try {
      final all = await _client.from(AppConstants.tableAchievements).select().order('xp_reward');
      final unlockedRows = userId == null
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                  .from(AppConstants.tableUserAchievements)
                  .select('achievement_id, unlocked_at')
                  .eq('user_id', userId) as List,
            );
      final unlockedMap = {for (final r in unlockedRows) r['achievement_id'] as String: r['unlocked_at'] as String};

      return Right(
        List<Map<String, dynamic>>.from(all as List).map((row) {
          final id = row['id'] as String;
          final unlockedAt = unlockedMap[id];
          return Achievement(
            id: id,
            code: row['code'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            icon: row['icon'] as String,
            xpReward: row['xp_reward'] as int,
            tier: AchievementTierX.fromKey(row['tier'] as String),
            isUnlocked: unlockedAt != null,
            unlockedAt: unlockedAt == null ? null : DateTime.parse(unlockedAt),
          );
        }).toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<UserLevel>> getMyLevel() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row =
          await _client.from(AppConstants.tableUserLevels).select().eq('user_id', userId).maybeSingle();
      if (row == null) return const Right(UserLevel(level: 1, totalXp: 0, xpToNextLevel: 100));
      return Right(
        UserLevel(
          level: row['level'] as int,
          totalXp: row['total_xp'] as int,
          xpToNextLevel: row['xp_to_next_level'] as int,
        ),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<Streak>> getMyStreak() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _client.from(AppConstants.tableStreaks).select().eq('user_id', userId).maybeSingle();
      if (row == null) return const Right(Streak(currentStreak: 0, longestStreak: 0));
      return Right(
        Streak(
          currentStreak: row['current_streak'] as int,
          longestStreak: row['longest_streak'] as int,
          lastActivityDate:
              row['last_activity_date'] == null ? null : DateTime.parse(row['last_activity_date'] as String),
        ),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Challenge>>> getChallenges() async {
    final userId = _currentUserId();
    try {
      final rows = await _client
          .from(AppConstants.tableChallenges)
          .select('*, challenge_participants(user_id, progress_value)')
          .order('starts_at', ascending: false);

      return Right(
        List<Map<String, dynamic>>.from(rows as List).map((row) {
          final participants = List<Map<String, dynamic>>.from(row['challenge_participants'] as List? ?? []);
          final mine = userId == null ? null : participants.where((p) => p['user_id'] == userId).firstOrNull;
          return Challenge(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            challengeType: ChallengeTypeX.fromKey(row['challenge_type'] as String),
            targetValue: (row['target_value'] as num).toDouble(),
            startsAt: DateTime.parse(row['starts_at'] as String),
            endsAt: DateTime.parse(row['ends_at'] as String),
            xpReward: row['xp_reward'] as int,
            myProgress: (mine?['progress_value'] as num?)?.toDouble() ?? 0,
            isJoined: mine != null,
            participantCount: participants.length,
          );
        }).toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> joinChallenge(String challengeId) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      await _client
          .from(AppConstants.tableChallengeParticipants)
          .upsert({'challenge_id': challengeId, 'user_id': userId});
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }
}
