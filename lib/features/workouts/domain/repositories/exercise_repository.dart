import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../entities/exercise.dart';

class ExerciseFilter extends Equatable {
  const ExerciseFilter({
    this.query,
    this.category,
    this.primaryMuscle,
    this.equipment,
    this.difficulty,
    this.favoritesOnly = false,
  });

  final String? query;
  final ExerciseCategory? category;
  final String? primaryMuscle;
  final String? equipment;
  final ExerciseDifficulty? difficulty;
  final bool favoritesOnly;

  @override
  List<Object?> get props =>
      [query, category, primaryMuscle, equipment, difficulty, favoritesOnly];
}

/// Offline-first: reads serve from the local cache instantly, refreshed
/// from Supabase in the background whenever connectivity allows, so the
/// exercise library and workout generator work fully offline after first
/// launch.
abstract interface class ExerciseRepository {
  Future<Result<List<Exercise>>> getExercises(ExerciseFilter filter);

  Future<Result<Exercise>> getExerciseById(String id);

  Future<Result<void>> toggleFavorite(String exerciseId,
      {required bool isFavorite});

  Stream<Set<String>> watchFavoriteIds();
}
