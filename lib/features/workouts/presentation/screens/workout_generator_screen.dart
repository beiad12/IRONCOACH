import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/services/workout_generator_service.dart';
import '../providers/workout_providers.dart';

enum _Equipment { fullGym, dumbbells, bodyweight }

const _durations = [20, 45, 60];

class WorkoutGeneratorScreen extends HookConsumerWidget {
  const WorkoutGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = useState(WorkoutGoal.hypertrophy);
    final difficulty = useState(ExerciseDifficulty.intermediate);
    final duration = useState(45);
    final equipment = useState(_Equipment.fullGym);
    final generated = useState<WorkoutTemplate?>(null);
    final isWorking = useState(false);

    List<String> resolveEquipment() => switch (equipment.value) {
          _Equipment.fullGym => const [],
          _Equipment.dumbbells => const ['dumbbell'],
          _Equipment.bodyweight => const ['__bodyweight_only__'],
        };

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
                  availableEquipment: resolveEquipment(),
                  durationMinutes: duration.value,
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

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Generator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          sectionLabel('Goal'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkoutGoal.values
                .map((g) => AppChip(label: g.label, selected: goal.value == g, onTap: () => goal.value = g))
                .toList(),
          ),
          const SizedBox(height: 20),
          sectionLabel('Experience level'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExerciseDifficulty.values
                .map(
                  (d) => AppChip(
                    label: d.name[0].toUpperCase() + d.name.substring(1),
                    selected: difficulty.value == d,
                    onTap: () => difficulty.value = d,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          sectionLabel('Duration'),
          Row(
            children: [
              for (final d in _durations) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(label: '$d min', selected: duration.value == d, onTap: () => duration.value = d),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          sectionLabel('Equipment'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                label: 'Full Gym',
                selected: equipment.value == _Equipment.fullGym,
                onTap: () => equipment.value = _Equipment.fullGym,
              ),
              AppChip(
                label: 'Dumbbells',
                selected: equipment.value == _Equipment.dumbbells,
                onTap: () => equipment.value = _Equipment.dumbbells,
              ),
              AppChip(
                label: 'Bodyweight',
                selected: equipment.value == _Equipment.bodyweight,
                onTap: () => equipment.value = _Equipment.bodyweight,
              ),
            ],
          ),
          const SizedBox(height: 28),
          GradientButton(label: 'Generate Plan', isLoading: isWorking.value, onPressed: generate),
          if (generated.value != null) ...[
            const SizedBox(height: 20),
            AppCard(
              borderColor: AppColors.emerald.withOpacity(0.25),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.emerald, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New plan ready — ${generated.value!.exercises.length} exercises, ${duration.value} min',
                      style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final te in generated.value!.exercises)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center, color: AppColors.electricBlue),
                title: Text(te.exercise.name),
                subtitle: Text('${te.targetSets} × ${te.targetRepsMin}-${te.targetRepsMax} reps · ${te.targetRestSeconds}s rest'),
              ),
            const SizedBox(height: 16),
            GradientButton(label: 'Start workout', isLoading: isWorking.value, onPressed: startWorkout),
          ],
        ],
      ),
    );
  }
}
