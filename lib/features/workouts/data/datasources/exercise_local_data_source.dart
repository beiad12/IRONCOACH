import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/local_db/app_database.dart';

class ExerciseLocalDataSource {
  ExerciseLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<CachedExercise>> getAll() => _db.select(_db.cachedExercises).get();

  Future<void> replaceAll(List<Map<String, dynamic>> remoteRows) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedExercises).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedExercises,
          remoteRows.map(
            (row) => CachedExercisesCompanion.insert(
              id: row['id'] as String,
              name: row['name'] as String,
              category: row['category'] as String,
              primaryMuscle: row['primary_muscle'] as String,
              secondaryMusclesJson: Value(jsonEncode(row['secondary_muscles'] ?? <String>[])),
              equipment: Value(row['equipment'] as String?),
              difficulty: row['difficulty'] as String,
              instructions: Value(row['instructions'] as String?),
              videoUrl: Value(row['video_url'] as String?),
              imageUrl: Value(row['image_url'] as String?),
            ),
          ),
        );
      });
    });
  }

  Future<Set<String>> getFavoriteIds() async {
    final rows = await _db.select(_db.cachedFavoriteExercises).get();
    return rows.map((r) => r.exerciseId).toSet();
  }

  Future<void> replaceFavoriteIds(Set<String> ids) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedFavoriteExercises).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedFavoriteExercises,
          ids.map((id) => CachedFavoriteExercisesCompanion.insert(exerciseId: id)),
        );
      });
    });
  }

  Future<void> setFavoriteLocally(String exerciseId, {required bool isFavorite}) async {
    if (isFavorite) {
      await _db
          .into(_db.cachedFavoriteExercises)
          .insertOnConflictUpdate(CachedFavoriteExercisesCompanion.insert(exerciseId: exerciseId));
    } else {
      await (_db.delete(_db.cachedFavoriteExercises)..where((t) => t.exerciseId.equals(exerciseId)))
          .go();
    }
  }
}
