import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/workout_providers.dart';

class WorkoutTemplateDetailScreen extends ConsumerWidget {
  const WorkoutTemplateDetailScreen({required this.templateId, super.key});
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(workoutTemplateByIdProvider(templateId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout template')),
      body: AsyncValueWidget(
        value: templateAsync,
        onRetry: () => ref.invalidate(workoutTemplateByIdProvider(templateId)),
        data: (template) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(template.name, style: Theme.of(context).textTheme.headlineSmall),
              if (template.description != null) ...[
                const SizedBox(height: 8),
                Text(template.description!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              for (final te in template.exercises)
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(te.exercise.name),
                  subtitle: Text(
                    '${te.targetSets} × ${te.targetRepsMin ?? "-"}-${te.targetRepsMax ?? "-"} reps · ${te.targetRestSeconds}s rest',
                  ),
                ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Start workout',
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
