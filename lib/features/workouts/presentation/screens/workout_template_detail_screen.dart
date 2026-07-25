import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/workout_providers.dart';

class WorkoutTemplateDetailScreen extends ConsumerWidget {
  const WorkoutTemplateDetailScreen({required this.templateId, super.key});
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(workoutTemplateByIdProvider(templateId));

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s workout')),
      body: AsyncValueWidget(
        value: templateAsync,
        onRetry: () => ref.invalidate(workoutTemplateByIdProvider(templateId)),
        data: (template) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(template.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${template.exercises.length} exercises · ${template.estimatedDurationMinutes ?? "-"} min'
                '${template.difficulty != null ? " · ${template.difficulty!.name}" : ""}',
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < template.exercises.length; i++)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  onTap: () => context.push(
                    '${RoutePaths.exerciseLibrary}/${template.exercises[i].exercise.id}',
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.electricBlue,
                              ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.exercises[i].exercise.name,
                              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${template.exercises[i].targetSets} sets × '
                              '${template.exercises[i].targetRepsMin ?? "-"}-${template.exercises[i].targetRepsMax ?? "-"} reps'
                              ' · ${template.exercises[i].exercise.primaryMuscle}',
                              style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.darkTextTertiary, size: 18),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.workoutGenerator),
                child: const Text('Generate a Different Plan'),
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: 'Start Workout',
                onPressed: () async {
                  final result = await ref
                      .read(workoutSessionRepositoryProvider)
                      .startSession(templateId: template.id, name: template.name);
                  if (!context.mounted) return;
                  result.match(
                    (failure) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
                    (session) =>
                        context.push(RoutePaths.activeWorkout.replaceFirst(':sessionId', session.id)),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
