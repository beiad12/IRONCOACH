import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai_coach/presentation/providers/ai_coach_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../nutrition/presentation/providers/nutrition_providers.dart';
import '../../../nutrition/presentation/widgets/calorie_ring.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);
    final profileAsync = ref.watch(myProfileProvider);
    final streakAsync = ref.watch(myStreakProvider);
    final summaryAsync = ref.watch(dailyNutritionSummaryControllerProvider(normalizedDate));
    final insightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (profile) => Text('Hey, ${profile?.displayName ?? profile?.username ?? 'there'}'),
          loading: () => const Text('IronCoach'),
          error: (_, __) => const Text('IronCoach'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myStreakProvider);
          ref.invalidate(dailyNutritionSummaryControllerProvider);
          ref.invalidate(aiInsightsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StreakCard(
                    streak: streakAsync.valueOrNull?.currentStreak ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.play_circle_fill,
                    label: 'Start workout',
                    onTap: () => context.push(RoutePaths.workoutGenerator),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    summaryAsync.when(
                      data: (summary) =>
                          CalorieRing(consumed: summary.calories, goal: summary.goals.calories),
                      loading: () => const SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Icon(Icons.error_outline),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's nutrition", style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => context.go(RoutePaths.nutrition),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: const Text('View details'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI insights', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () async {
                    final result = await ref.read(aiRepositoryProvider).generateDailyPlan();
                    ref.invalidate(aiInsightsProvider);
                    if (context.mounted) {
                      result.match(
                        (failure) => ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
                        (_) => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text("Today's plan is ready"))),
                      );
                    }
                  },
                  child: const Text('Plan my day'),
                ),
              ],
            ),
            insightsAsync.when(
              data: (insights) {
                if (insights.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No insights yet — tap "Plan my day" or chat with a coach.'),
                  );
                }
                return Column(
                  children: insights
                      .take(3)
                      .map(
                        (insight) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.auto_awesome, color: AppColors.emberOrange),
                            title: Text(insight.title),
                            subtitle: Text(insight.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.local_fire_department, color: AppColors.streakFlame, size: 28),
            const SizedBox(height: 8),
            Text('$streak day streak', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
