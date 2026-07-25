import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../providers/gamification_providers.dart';
import '../widgets/achievements_grid.dart';

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
                    : AppCard(
                        margin: const EdgeInsets.only(bottom: 16),
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
                            Text(
                              '${level.xpToNextLevel} XP to next level',
                              style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              AchievementsGrid(achievements: items),
            ],
          );
        },
      ),
    );
  }
}
