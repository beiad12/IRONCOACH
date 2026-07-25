import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/local_db/app_database.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/exercise_local_data_source.dart';
import '../datasources/exercise_remote_data_source.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl({
    required ExerciseRemoteDataSource remote,
    required ExerciseLocalDataSource local,
    required AppDatabase db,
    required String? Function() currentUserId,
  })  : _remote = remote,
        _local = local,
        _db = db,
        _currentUserId = currentUserId;

  final ExerciseRemoteDataSource _remote;
  final ExerciseLocalDataSource _local;
  final AppDatabase _db;
  final String? Function() _currentUserId;

  @override
  Future<Result<List<Exercise>>> getExercises(ExerciseFilter filter) async {
    try {
      await _refreshFromRemoteIfPossible();
      final cached = await _local.getAll();
      final favoriteIds = await _local.getFavoriteIds();
      var exercises = cached.map((row) => _mapRow(row, favoriteIds)).toList();

      if (filter.query != null && filter.query!.trim().isNotEmpty) {
        final q = filter.query!.toLowerCase();
        exercises =
            exercises.where((e) => e.name.toLowerCase().contains(q)).toList();
      }
      if (filter.category != null) {
        exercises =
            exercises.where((e) => e.category == filter.category).toList();
      }
      if (filter.primaryMuscle != null) {
        exercises = exercises
            .where((e) => e.primaryMuscle == filter.primaryMuscle)
            .toList();
      }
      if (filter.equipment != null) {
        exercises =
            exercises.where((e) => e.equipment == filter.equipment).toList();
      }
      if (filter.difficulty != null) {
        exercises =
            exercises.where((e) => e.difficulty == filter.difficulty).toList();
      }
      if (filter.favoritesOnly) {
        exercises = exercises.where((e) => e.isFavorite).toList();
      }
      return Right(exercises);
    } on Object catch (e) {
      return Left(Failure.cache(e.toString()));
    }
  }

  @override
  Future<Result<Exercise>> getExerciseById(String id) async {
    try {
      final cached = await _local.getAll();
      final favoriteIds = await _local.getFavoriteIds();
      final row = cached.where((r) => r.id == id).firstOrNull;
      if (row == null) return Left(Failure.notFound('Exercise not found'));
      return Right(_mapRow(row, favoriteIds));
    } on Object catch (e) {
      return Left(Failure.cache(e.toString()));
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String exerciseId,
      {required bool isFavorite}) async {
    await _local.setFavoriteLocally(exerciseId, isFavorite: isFavorite);
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      await _remote.setFavorite(userId, exerciseId, isFavorite: isFavorite);
      return const Right(null);
    } on Object {
      // Offline or transient failure: local state is already updated;
      // enqueue for the sync engine to reconcile once online.
      await _db.enqueueSync(
        entityTable: 'favorite_exercises',
        entityId: exerciseId,
        operation: isFavorite ? 'insert' : 'delete',
        payloadJson: jsonEncode({'user_id': userId, 'exercise_id': exerciseId}),
      );
      return const Right(null);
    }
  }

  @override
  Stream<Set<String>> watchFavoriteIds() {
    return _db
        .select(_db.cachedFavoriteExercises)
        .watch()
        .map((rows) => rows.map((r) => r.exerciseId).toSet());
  }

  Future<void> _refreshFromRemoteIfPossible() async {
    try {
      final remoteRows = await _remote.fetchAll();
      await _local.replaceAll(remoteRows);
      final userId = _currentUserId();
      if (userId != null) {
        final favoriteIds = await _remote.fetchFavoriteIds(userId);
        await _local.replaceFavoriteIds(favoriteIds);
      }
    } on Object {
      // No connectivity or remote error: fall back silently to whatever
      // is already cached locally (first-launch-with-no-network is the
      // only case where this yields an empty library).
    }
  }

  Exercise _mapRow(CachedExercise row, Set<String> favoriteIds) {
    return Exercise(
      id: row.id,
      name: row.name,
      category: ExerciseCategoryX.fromKey(row.category),
      primaryMuscle: row.primaryMuscle,
      secondaryMuscles:
          List<String>.from(jsonDecode(row.secondaryMusclesJson) as List),
      equipment: row.equipment,
      difficulty: ExerciseDifficultyX.fromKey(row.difficulty),
      instructions: row.instructions,
      videoUrl: row.videoUrl,
      imageUrl: row.imageUrl,
      isFavorite: favoriteIds.contains(row.id),
    );
  }
}
