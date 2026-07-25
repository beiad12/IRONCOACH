import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';

enum AchievementTier { bronze, silver, gold, platinum }

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String code,
    required String name,
    required String description,
    required String icon,
    required int xpReward,
    required AchievementTier tier,
    @Default(false) bool isUnlocked,
    DateTime? unlockedAt,
  }) = _Achievement;
}

extension AchievementTierX on AchievementTier {
  static AchievementTier fromKey(String key) => AchievementTier.values
      .firstWhere((e) => e.name == key, orElse: () => AchievementTier.bronze);
}
