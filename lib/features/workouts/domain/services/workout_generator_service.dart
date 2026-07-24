import 'dart:math';

import '../entities/exercise.dart';
import '../entities/workout_template.dart';

class WorkoutGeneratorParams {
  const WorkoutGeneratorParams({
    required this.goal,
    required this.difficulty,
    required this.availableEquipment,
    this.targetMuscles = const [],
    this.durationMinutes = 45,
  });

  final WorkoutGoal goal;
  final ExerciseDifficulty difficulty;

  /// Empty means "no equipment restriction" (bodyweight excluded is never
  /// implied — bodyweight exercises are always eligible).
  final List<String> availableEquipment;
  final List<String> targetMuscles;
  final int durationMinutes;
}

/// Deterministic, offline-capable workout generator: no network or AI call
/// required, so "Generate workout" always works even with no connectivity.
/// The AI Coach chat (`ai_coach` feature) offers a second, LLM-driven path
/// to a workout for users who want a conversational, more tailored result —
/// this service is the fast, reliable default.
class WorkoutGeneratorService {
  const WorkoutGeneratorService();

  static const _minutesPerSet = 3; // includes rest

  WorkoutTemplate generate({
    required WorkoutGeneratorParams params,
    required List<Exercise> library,
  }) {
    final eligible = library.where((e) {
      final equipmentOk = params.availableEquipment.isEmpty ||
          e.equipment == null ||
          e.equipment == 'bodyweight' ||
          params.availableEquipment.contains(e.equipment);
      final muscleOk = params.targetMuscles.isEmpty ||
          params.targetMuscles.contains(e.primaryMuscle) ||
          e.secondaryMuscles.any(params.targetMuscles.contains);
      final difficultyOk = _difficultyRank(e.difficulty) <= _difficultyRank(params.difficulty) + 1;
      return equipmentOk && muscleOk && difficultyOk && e.category == ExerciseCategory.strength;
    }).toList()
      ..shuffle(Random());

    // Prioritize compound movements first (bigger training effect per set),
    // then fill remaining slots with isolation work.
    final compounds = eligible.where((e) => e.mechanic == ExerciseMechanic.compound).toList();
    final isolations = eligible.where((e) => e.mechanic != ExerciseMechanic.compound).toList();

    final totalSlots = (params.durationMinutes / _minutesPerSet / _setsFor(params.goal)).round().clamp(3, 8);
    final selected = <Exercise>[
      ...compounds.take((totalSlots * 0.6).ceil()),
      ...isolations.take(totalSlots),
    ].take(totalSlots).toList();

    final sets = _setsFor(params.goal);
    final repRange = _repRangeFor(params.goal);
    final rest = _restFor(params.goal);

    return WorkoutTemplate(
      id: '',
      name: '${params.goal.label} — ${params.difficulty.name[0].toUpperCase()}${params.difficulty.name.substring(1)}',
      description: 'Auto-generated ${params.durationMinutes}-minute session targeting '
          '${params.targetMuscles.isEmpty ? "full body" : params.targetMuscles.join(", ")}.',
      goal: params.goal,
      difficulty: params.difficulty,
      estimatedDurationMinutes: params.durationMinutes,
      isAiGenerated: false,
      exercises: [
        for (var i = 0; i < selected.length; i++)
          TemplateExercise(
            id: '',
            exercise: selected[i],
            position: i,
            targetSets: sets,
            targetRepsMin: repRange.$1,
            targetRepsMax: repRange.$2,
            targetRestSeconds: rest,
          ),
      ],
    );
  }

  int _difficultyRank(ExerciseDifficulty d) => switch (d) {
        ExerciseDifficulty.beginner => 0,
        ExerciseDifficulty.intermediate => 1,
        ExerciseDifficulty.advanced => 2,
      };

  int _setsFor(WorkoutGoal goal) => switch (goal) {
        WorkoutGoal.strength => 5,
        WorkoutGoal.hypertrophy => 4,
        WorkoutGoal.endurance => 3,
        WorkoutGoal.fatLoss => 3,
        WorkoutGoal.generalFitness => 3,
      };

  (int, int) _repRangeFor(WorkoutGoal goal) => switch (goal) {
        WorkoutGoal.strength => (3, 6),
        WorkoutGoal.hypertrophy => (8, 12),
        WorkoutGoal.endurance => (15, 20),
        WorkoutGoal.fatLoss => (12, 15),
        WorkoutGoal.generalFitness => (10, 12),
      };

  int _restFor(WorkoutGoal goal) => switch (goal) {
        WorkoutGoal.strength => 180,
        WorkoutGoal.hypertrophy => 90,
        WorkoutGoal.endurance => 45,
        WorkoutGoal.fatLoss => 60,
        WorkoutGoal.generalFitness => 75,
      };
}
