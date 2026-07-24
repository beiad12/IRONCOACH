import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    required int level,
    required int totalXp,
    required int currentStreak,
  }) = _LeaderboardEntry;
}
