import 'package:freezed_annotation/freezed_annotation.dart';

import 'exercise.dart';

part 'workout_template.freezed.dart';

enum WorkoutGoal { strength, hypertrophy, endurance, fatLoss, generalFitness }

@freezed
class TemplateExercise with _$TemplateExercise {
  const factory TemplateExercise({
    required String id,
    required Exercise exercise,
    required int position,
    @Default(3) int targetSets,
    int? targetRepsMin,
    int? targetRepsMax,
    @Default(90) int targetRestSeconds,
    double? targetWeightKg,
    String? notes,
  }) = _TemplateExercise;
}

@freezed
class WorkoutTemplate with _$WorkoutTemplate {
  const factory WorkoutTemplate({
    required String id,
    String? ownerId,
    required String name,
    String? description,
    WorkoutGoal? goal,
    ExerciseDifficulty? difficulty,
    int? estimatedDurationMinutes,
    @Default(false) bool isAiGenerated,
    @Default(false) bool isPublic,
    @Default(false) bool isFavorite,
    @Default([]) List<TemplateExercise> exercises,
  }) = _WorkoutTemplate;
}

extension WorkoutGoalX on WorkoutGoal {
  String get key => switch (this) {
        WorkoutGoal.strength => 'strength',
        WorkoutGoal.hypertrophy => 'hypertrophy',
        WorkoutGoal.endurance => 'endurance',
        WorkoutGoal.fatLoss => 'fat_loss',
        WorkoutGoal.generalFitness => 'general_fitness',
      };

  String get label => switch (this) {
        WorkoutGoal.strength => 'Strength',
        WorkoutGoal.hypertrophy => 'Hypertrophy',
        WorkoutGoal.endurance => 'Endurance',
        WorkoutGoal.fatLoss => 'Fat loss',
        WorkoutGoal.generalFitness => 'General fitness',
      };

  static WorkoutGoal? fromKey(String? key) => switch (key) {
        'strength' => WorkoutGoal.strength,
        'hypertrophy' => WorkoutGoal.hypertrophy,
        'endurance' => WorkoutGoal.endurance,
        'fat_loss' => WorkoutGoal.fatLoss,
        'general_fitness' => WorkoutGoal.generalFitness,
        _ => null,
      };
}
