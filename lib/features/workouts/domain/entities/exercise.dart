import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';

enum ExerciseCategory { strength, cardio, mobility, plyometric, balance }

enum ExerciseDifficulty { beginner, intermediate, advanced }

enum ExerciseMechanic { compound, isolation }

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    required ExerciseCategory category,
    required String primaryMuscle,
    required List<String> secondaryMuscles,
    required ExerciseDifficulty difficulty,
    String? equipment,
    ExerciseMechanic? mechanic,
    String? instructions,
    String? videoUrl,
    String? imageUrl,
    @Default(false) bool isFavorite,
  }) = _Exercise;
}

extension ExerciseCategoryX on ExerciseCategory {
  static ExerciseCategory fromKey(String key) =>
      ExerciseCategory.values.firstWhere((e) => e.name == key, orElse: () => ExerciseCategory.strength);
}

extension ExerciseDifficultyX on ExerciseDifficulty {
  static ExerciseDifficulty fromKey(String key) => ExerciseDifficulty.values
      .firstWhere((e) => e.name == key, orElse: () => ExerciseDifficulty.beginner);
}

extension ExerciseMechanicX on ExerciseMechanic {
  static ExerciseMechanic? fromKey(String? key) =>
      key == null ? null : ExerciseMechanic.values.firstWhereOrNull((e) => e.name == key);
}
