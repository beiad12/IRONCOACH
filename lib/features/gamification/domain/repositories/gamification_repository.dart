import '../../../../core/utils/result.dart';
import '../entities/achievement.dart';
import '../entities/challenge.dart';
import '../entities/user_level.dart';

abstract interface class GamificationRepository {
  Future<Result<List<Achievement>>> getAchievements();

  Future<Result<UserLevel>> getMyLevel();

  Future<Result<Streak>> getMyStreak();

  Future<Result<List<Challenge>>> getChallenges();

  Future<Result<void>> joinChallenge(String challengeId);
}
