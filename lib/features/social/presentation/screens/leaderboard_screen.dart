import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/social_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final myId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: AsyncValueWidget(
        value: leaderboardAsync,
        onRetry: () => ref.invalidate(leaderboardProvider),
        data: (entries) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              final isMe = entry.userId == myId;
              return Card(
                color: isMe ? AppColors.emberOrange.withValues(alpha: 0.1) : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i < 3 ? AppColors.xpGold.withValues(alpha: 0.3) : null,
                    backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
                    child: entry.avatarUrl == null ? Text('${i + 1}') : null,
                  ),
                  title: Text(entry.displayName ?? entry.username),
                  subtitle: Text('Level ${entry.level} · ${entry.totalXp} XP'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: AppColors.streakFlame, size: 18),
                      const SizedBox(width: 4),
                      Text('${entry.currentStreak}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
