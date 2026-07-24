import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../domain/entities/achievement.dart';
import '../providers/gamification_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final levelAsync = ref.watch(myLevelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: AsyncValueWidget(
        value: achievementsAsync,
        onRetry: () => ref.invalidate(achievementsProvider),
        data: (items) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              levelAsync.when(
                data: (level) => level == null
                    ? const SizedBox.shrink()
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Level ${level.level}', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: level.progress,
                                  minHeight: 8,
                                  color: AppColors.xpGold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${level.xpToNextLevel} XP to next level'),
                            ],
                          ),
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              for (final achievement in items) _AchievementTile(achievement: achievement),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: achievement.isUnlocked ? 1 : 0.4,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _tierColor(achievement.tier).withValues(alpha: 0.2),
            child: Icon(Icons.emoji_events, color: _tierColor(achievement.tier)),
          ),
          title: Text(achievement.name),
          subtitle: Text(achievement.description),
          trailing: Text('+${achievement.xpReward} XP'),
        ),
      ),
    );
  }

  Color _tierColor(AchievementTier tier) => switch (tier) {
        AchievementTier.bronze => const Color(0xFFCD7F32),
        AchievementTier.silver => const Color(0xFFC0C0C0),
        AchievementTier.gold => AppColors.xpGold,
        AchievementTier.platinum => const Color(0xFFB9F2FF),
      };
}
