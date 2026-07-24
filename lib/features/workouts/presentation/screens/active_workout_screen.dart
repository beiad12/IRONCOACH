import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../providers/active_workout_controller.dart';
import '../providers/rest_timer_controller.dart';
import '../providers/workout_providers.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/set_log_row.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(activeWorkoutControllerProvider(sessionId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active workout'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => _confirmExit(context)),
          actions: [
            TextButton(
              onPressed: () async {
                final session =
                    await ref.read(activeWorkoutControllerProvider(sessionId).notifier).finish();
                if (!context.mounted) return;
                context.pushReplacement(
                  RoutePaths.workoutSummary.replaceFirst(':sessionId', session.id),
                );
              },
              child: const Text('Finish'),
            ),
          ],
        ),
        body: AsyncValueWidget(
          value: sessionAsync,
          data: (session) => _ActiveWorkoutBody(session: session),
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave workout?'),
        content: const Text('Your progress is saved automatically — you can resume any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Stay')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _ActiveWorkoutBody extends ConsumerWidget {
  const _ActiveWorkoutBody({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = session.templateId == null
        ? null
        : ref.watch(workoutTemplateByIdProvider(session.templateId!));

    return Column(
      children: [
        const RestTimerWidget(),
        Expanded(
          child: templateAsync == null
              ? _AdHocExerciseList(session: session)
              : templateAsync.when(
                  data: (template) => _TemplateExerciseList(session: session, template: template),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _AdHocExerciseList(session: session),
                ),
        ),
      ],
    );
  }
}

class _TemplateExerciseList extends ConsumerWidget {
  const _TemplateExerciseList({required this.session, required this.template});
  final WorkoutSession session;
  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsByExercise = session.setsByExercise;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: template.exercises.length,
      itemBuilder: (context, i) {
        final te = template.exercises[i];
        return _ExerciseSection(
          exercise: te.exercise,
          sets: setsByExercise[te.exercise.id] ?? const [],
          restSeconds: te.targetRestSeconds,
          sessionId: session.id,
        );
      },
    );
  }
}

class _AdHocExerciseList extends ConsumerWidget {
  const _AdHocExerciseList({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsByExercise = session.setsByExercise;
    if (setsByExercise.isEmpty) {
      return const Center(child: Text('Add an exercise from the library to get started.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in setsByExercise.entries)
          _ExerciseSection(
            exercise: null,
            exerciseId: entry.key,
            sets: entry.value,
            restSeconds: AppConstants.defaultRestSeconds,
            sessionId: session.id,
          ),
      ],
    );
  }
}

class _ExerciseSection extends ConsumerWidget {
  const _ExerciseSection({
    this.exercise,
    String? exerciseId,
    required this.sets,
    required this.restSeconds,
    required this.sessionId,
  }) : exerciseId = exerciseId ?? '';

  final Exercise? exercise;
  final String exerciseId;
  final List<WorkoutSet> sets;
  final int restSeconds;
  final String sessionId;

  String get _resolvedExerciseId => exercise?.id ?? exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activeWorkoutControllerProvider(sessionId).notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise?.name ?? 'Exercise', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final set in sets)
              SetLogRow(
                set: set,
                onWeightChanged: (v) => controller.updateSet(set.copyWith(weightKg: v)),
                onRepsChanged: (v) => controller.updateSet(set.copyWith(reps: v)),
                onToggleCompleted: () {
                  controller.updateSet(set.copyWith(isCompleted: !set.isCompleted));
                  if (!set.isCompleted) {
                    ref.read(restTimerControllerProvider.notifier).start(restSeconds);
                  }
                },
                onDelete: () => controller.removeSet(set.id),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add set'),
              onPressed: () => controller.logSet(exerciseId: _resolvedExerciseId),
            ),
          ],
        ),
      ),
    );
  }
}
