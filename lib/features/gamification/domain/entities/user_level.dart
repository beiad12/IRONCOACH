import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_level.freezed.dart';

@freezed
class UserLevel with _$UserLevel {
  const factory UserLevel({
    required int level,
    required int totalXp,
    required int xpToNextLevel,
  }) = _UserLevel;

  const UserLevel._();

  int get xpForCurrentLevel => level * 100;
  double get progress =>
      xpForCurrentLevel == 0 ? 0 : (xpForCurrentLevel - xpToNextLevel) / xpForCurrentLevel;
}

@freezed
class Streak with _$Streak {
  const factory Streak({
    required int currentStreak,
    required int longestStreak,
    DateTime? lastActivityDate,
  }) = _Streak;
}
