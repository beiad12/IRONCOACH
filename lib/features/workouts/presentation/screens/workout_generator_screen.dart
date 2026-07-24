import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/services/workout_generator_service.dart';
import '../providers/workout_providers.dart';

class WorkoutGeneratorScreen extends HookConsumerWidget {
  const WorkoutGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = useState(WorkoutGoal.hypertrophy);
    final difficulty = useState(ExerciseDifficulty.intermediate);
    final duration = useState(45.0);
    final generated = useState<WorkoutTemplate?>(null);
    final isWorking = useState(false);

    Future<void> generate() async {
      isWorking.value = true;
      final libraryResult = await ref.read(exerciseRepositoryProvider).getExercises(const ExerciseFilter());
      isWorking.value = false;
      libraryResult.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (library) {
          final template = ref.read(workoutGeneratorServiceProvider).generate(
                params: WorkoutGeneratorParams(
                  goal: goal.value,
                  difficulty: difficulty.value,
                  availableEquipment: const [],
                  durationMinutes: duration.value.round(),
                ),
                library: library,
              );
          generated.value = template;
        },
      );
    }

    Future<void> startWorkout() async {
      final template = generated.value;
      if (template == null) return;
      isWorking.value = true;

      final saveResult = await ref.read(workoutTemplateRepositoryProvider).saveTemplate(template);
      final saved = saveResult.match((failure) {
        isWorking.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.displayMessage)));
        }
        return null;
      }, (t) => t);
      if (saved == null) return;

      final sessionResult = await ref
          .read(workoutSessionRepositoryProvider)
          .startSession(templateId: saved.id, name: saved.name);
      isWorking.value = false;
      if (!context.mounted) return;

      sessionResult.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (session) => context.push(RoutePaths.activeWorkout.replaceFirst(':sessionId', session.id)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Generate a workout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Goal', style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: WorkoutGoal.values
                .map((g) => ChoiceChip(
                      label: Text(g.label),
                      selected: goal.value == g,
                      onSelected: (_) => goal.value = g,
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Experience level', style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: ExerciseDifficulty.values
                .map((d) => ChoiceChip(
                      label: Text(d.name),
                      selected: difficulty.value == d,
                      onSelected: (_) => difficulty.value = d,
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Duration: ${duration.value.round()} min', style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: duration.value,
            min: 20,
            max: 90,
            divisions: 14,
            label: '${duration.value.round()} min',
            onChanged: (v) => duration.value = v,
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Generate', isLoading: isWorking.value, onPressed: generate),
          if (generated.value != null) ...[
            const SizedBox(height: 24),
            Text(generated.value!.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final te in generated.value!.exercises)
              ListTile(
                dense: true,
                leading: const Icon(Icons.fitness_center),
                title: Text(te.exercise.name),
                subtitle: Text('${te.targetSets} × ${te.targetRepsMin}-${te.targetRepsMax} reps · ${te.targetRestSeconds}s rest'),
              ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Start workout', isLoading: isWorking.value, onPressed: startWorkout),
          ],
        ],
      ),
    );
  }
}
