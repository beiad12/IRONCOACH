import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../ai_coach/presentation/providers/ai_coach_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../progress/domain/entities/body_measurement.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../workouts/domain/entities/workout_template.dart';
import '../../../workouts/presentation/providers/workout_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final streakAsync = ref.watch(myStreakProvider);
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);
    final templatesAsync = ref.watch(workoutTemplatesProvider());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myStreakProvider);
            ref.invalidate(bodyMeasurementsProvider);
            ref.invalidate(aiInsightsProvider);
            ref.invalidate(workoutTemplatesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      profileAsync.when(
                        data: (profile) => Text(
                          profile?.displayName ?? profile?.username ?? 'there',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        loading: () => const SizedBox(height: 28),
                        error: (_, __) => const Text('IronCoach'),
                      ),
                    ],
                  ),
                  _BellButton(onTap: () => context.push(RoutePaths.notifications)),
                ],
              ),
              const SizedBox(height: 20),
              templatesAsync.when(
                data: (templates) => _TodayWorkoutCard(template: _pickTodayTemplate(templates)),
                loading: () => const AppCard(child: SizedBox(height: 120)),
                error: (_, __) => _TodayWorkoutCard(template: null),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: '${streakAsync.valueOrNull?.currentStreak ?? 0} days',
                      valueColor: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _WeightStatCard(measurementsAsync: measurementsAsync)),
                ],
              ),
              const SizedBox(height: 14),
              insightsAsync.when(
                data: (insights) => insights.isEmpty
                    ? _PlanMyDayCard(
                        onTap: () async {
                          final result = await ref.read(aiRepositoryProvider).generateDailyPlan();
                          ref.invalidate(aiInsightsProvider);
                          if (context.mounted) {
                            result.match(
                              (failure) => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
                              (_) => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Today's plan is ready")),
                              ),
                            );
                          }
                        },
                      )
                    : _CoachNoteCard(title: insights.first.title, body: insights.first.body),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.eco_outlined,
                      iconColor: AppColors.emerald,
                      label: 'Nutrition',
                      onTap: () => context.push(RoutePaths.nutrition),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.groups_outlined,
                      iconColor: AppColors.electricBlue,
                      label: 'Community',
                      onTap: () => context.push(RoutePaths.community),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PremiumBanner(onTap: () => context.push(RoutePaths.premium)),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  WorkoutTemplate? _pickTodayTemplate(List<WorkoutTemplate> templates) {
    if (templates.isEmpty) return null;
    final favorite = templates.where((t) => t.isFavorite).toList();
    return favorite.isNotEmpty ? favorite.first : templates.first;
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 14,
      onTap: onTap,
      child: const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.notifications_outlined, color: AppColors.darkTextPrimary, size: 19),
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({required this.template});
  final WorkoutTemplate? template;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.heroCardGradient,
      borderColor: AppColors.electricBlue.withOpacity(0.22),
      onTap: () => template == null
          ? context.push(RoutePaths.workoutGenerator)
          : context.push(RoutePaths.workoutTemplateDetail.replaceFirst(':templateId', template!.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S WORKOUT",
            style: TextStyle(
              color: AppColors.electricBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            template?.name ?? 'Generate your first workout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            template == null
                ? 'Tell us your goal and we\'ll build one in seconds'
                : '${template!.exercises.length} exercises · ${template!.estimatedDurationMinutes ?? "-"} min'
                    '${template!.difficulty != null ? " · ${template!.difficulty!.name}" : ""}',
            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: template == null ? 'Generate workout' : 'Start Workout',
            height: 44,
            onPressed: () => template == null
                ? context.push(RoutePaths.workoutGenerator)
                : context.push(RoutePaths.workoutTemplateDetail.replaceFirst(':templateId', template!.id)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.valueColor});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _WeightStatCard extends StatelessWidget {
  const _WeightStatCard({required this.measurementsAsync});
  final AsyncValue<List<BodyMeasurement>> measurementsAsync;

  @override
  Widget build(BuildContext context) {
    final measurements = measurementsAsync.valueOrNull ?? const <BodyMeasurement>[];
    final withWeight = measurements.where((m) => m.weightKg != null).toList();

    if (withWeight.length < 2) {
      return const _StatCard(label: 'Weight', value: '—', valueColor: AppColors.darkTextPrimary);
    }
    final newest = withWeight.first.weightKg!;
    final oldest = withWeight.last.weightKg!;
    final delta = oldest - newest;
    final sign = delta >= 0 ? '-' : '+';
    return _StatCard(
      label: 'Weight',
      value: '$sign${delta.abs().toStringAsFixed(1)}kg',
      valueColor: AppColors.emerald,
    );
  }
}

class _CoachNoteCard extends StatelessWidget {
  const _CoachNoteCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(RoutePaths.aiCoach),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.electricBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMyDayCard extends StatelessWidget {
  const _PlanMyDayCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.electricBlue, size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Your coach is ready — plan my day',
              style: TextStyle(color: AppColors.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.darkTextTertiary),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.premiumCardGradient,
      borderColor: AppColors.electricBlue.withOpacity(0.28),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Go Premium', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                const Text(
                  'Unlimited AI coaching & analytics',
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: AppColors.electricBlue),
        ],
      ),
    );
  }
}
