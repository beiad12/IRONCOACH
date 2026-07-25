import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../social/domain/entities/post.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../providers/workout_providers.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(workoutSessionByIdProvider(sessionId));

    return Scaffold(
      body: SafeArea(
        child: AsyncValueWidget(
          value: sessionAsync,
          data: (session) {
            final completedSets = session.sets.where((s) => s.isCompleted && !s.isWarmup).toList();
            final duration = session.elapsed;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 32, color: AppColors.emerald),
                  ).animate().scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        duration: 450.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Workout Complete', style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(session.name, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _StatTile(label: 'Duration', value: '${duration.inMinutes} min')),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(label: 'Sets', value: '${completedSets.length}')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: 'Volume',
                        value: '${session.totalVolumeKg.round()} kg',
                        valueColor: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share with friends'),
                  onPressed: () async {
                    final result = await ref.read(socialRepositoryProvider).createPost(
                          postType: PostType.workout,
                          caption: '${session.name} · ${session.totalVolumeKg.round()} kg volume',
                          workoutSessionId: session.id,
                        );
                    if (!context.mounted) return;
                    result.match(
                      (failure) => ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
                      (_) => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Shared to your feed'))),
                    );
                  },
                ),
                const SizedBox(height: 12),
                GradientButton(label: 'Done', onPressed: () => context.go(RoutePaths.workouts)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: valueColor ?? AppColors.darkTextPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
