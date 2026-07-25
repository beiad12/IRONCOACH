import 'package:flutter_test/flutter_test.dart';
import 'package:ironcoach/features/workouts/domain/entities/exercise.dart';
import 'package:ironcoach/features/workouts/domain/entities/workout_template.dart';
import 'package:ironcoach/features/workouts/domain/services/workout_generator_service.dart';

Exercise _exercise({
  required String id,
  required String primaryMuscle,
  ExerciseMechanic mechanic = ExerciseMechanic.compound,
  ExerciseDifficulty difficulty = ExerciseDifficulty.beginner,
  String? equipment,
}) {
  return Exercise(
    id: id,
    name: id,
    category: ExerciseCategory.strength,
    primaryMuscle: primaryMuscle,
    secondaryMuscles: const [],
    difficulty: difficulty,
    mechanic: mechanic,
    equipment: equipment,
  );
}

void main() {
  final service = const WorkoutGeneratorService();

  final library = [
    _exercise(id: 'squat', primaryMuscle: 'quadriceps', equipment: 'barbell'),
    _exercise(id: 'bench', primaryMuscle: 'chest', equipment: 'barbell'),
    _exercise(id: 'row', primaryMuscle: 'back', equipment: 'barbell'),
    _exercise(
        id: 'curl',
        primaryMuscle: 'biceps',
        mechanic: ExerciseMechanic.isolation,
        equipment: 'dumbbell'),
    _exercise(
      id: 'pushdown',
      primaryMuscle: 'triceps',
      mechanic: ExerciseMechanic.isolation,
      equipment: 'cable',
    ),
    _exercise(
      id: 'advanced_lift',
      primaryMuscle: 'back',
      difficulty: ExerciseDifficulty.advanced,
      equipment: 'barbell',
    ),
  ];

  test('generates a non-empty template respecting the requested goal', () {
    final template = service.generate(
      params: const WorkoutGeneratorParams(
        goal: WorkoutGoal.hypertrophy,
        difficulty: ExerciseDifficulty.beginner,
        availableEquipment: ['barbell', 'dumbbell', 'cable'],
        durationMinutes: 45,
      ),
      library: library,
    );

    expect(template.goal, WorkoutGoal.hypertrophy);
    expect(template.exercises, isNotEmpty);
    // Hypertrophy rep range is 8-12 per the service's internal mapping.
    for (final te in template.exercises) {
      expect(te.targetRepsMin, 8);
      expect(te.targetRepsMax, 12);
    }
  });

  test('excludes exercises requiring unavailable equipment', () {
    final template = service.generate(
      params: const WorkoutGeneratorParams(
        goal: WorkoutGoal.strength,
        difficulty: ExerciseDifficulty.advanced,
        availableEquipment: ['dumbbell'],
        durationMinutes: 30,
      ),
      library: library,
    );

    final usedEquipment =
        template.exercises.map((te) => te.exercise.equipment).toSet();
    expect(usedEquipment.difference({'dumbbell', 'bodyweight', null}), isEmpty);
  });

  test('strength goal prescribes low rep ranges and longer rest', () {
    final template = service.generate(
      params: const WorkoutGeneratorParams(
        goal: WorkoutGoal.strength,
        difficulty: ExerciseDifficulty.advanced,
        availableEquipment: [],
        durationMinutes: 60,
      ),
      library: library,
    );

    for (final te in template.exercises) {
      expect(te.targetRepsMax, lessThanOrEqualTo(6));
      expect(te.targetRestSeconds, 180);
    }
  });
}
