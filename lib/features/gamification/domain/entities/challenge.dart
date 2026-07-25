import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge.freezed.dart';

enum ChallengeType { workoutCount, volume, streak, nutritionAdherence }

@freezed
class Challenge with _$Challenge {
  const factory Challenge({
    required String id,
    required String name,
    required String description,
    required ChallengeType challengeType,
    required double targetValue,
    required DateTime startsAt,
    required DateTime endsAt,
    required int xpReward,
    @Default(0) double myProgress,
    @Default(false) bool isJoined,
    @Default(0) int participantCount,
  }) = _Challenge;

  const Challenge._();

  double get progressPercent =>
      targetValue == 0 ? 0 : (myProgress / targetValue).clamp(0, 1);
  bool get isActive => DateTime.now().isBefore(endsAt);
}

extension ChallengeTypeX on ChallengeType {
  static ChallengeType fromKey(String key) => switch (key) {
        'workout_count' => ChallengeType.workoutCount,
        'volume' => ChallengeType.volume,
        'streak' => ChallengeType.streak,
        'nutrition_adherence' => ChallengeType.nutritionAdherence,
        _ => ChallengeType.workoutCount,
      };
}
