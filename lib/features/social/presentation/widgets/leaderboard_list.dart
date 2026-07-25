import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// Shared leaderboard list — used by the standalone [LeaderboardScreen] and
/// by the Community hub's Leaderboard tab.
class LeaderboardList extends ConsumerWidget {
  const LeaderboardList({required this.entries, super.key});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const EmptyState(icon: Icons.leaderboard_outlined, title: 'No leaderboard data yet');
    }
    final myId = ref.watch(currentUserProvider)?.id;

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _LeaderboardRow(rank: i + 1, entry: entries[i], isMe: entries[i].userId == myId),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry, required this.isMe});
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: isMe ? AppColors.electricBlue.withValues(alpha: 0.35) : null,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? AppColors.xpGold : AppColors.darkTextTertiary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.darkActivePill,
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName ?? entry.username,
                  style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Level ${entry.level} · ${entry.totalXp} XP',
                  style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.streakFlame, size: 16),
              const SizedBox(width: 4),
              Text('${entry.currentStreak}', style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
