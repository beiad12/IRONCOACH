import 'package:drift/drift.dart';

import '../../../../core/local_db/app_database.dart';

class WorkoutSessionLocalDataSource {
  WorkoutSessionLocalDataSource(this._db);

  final AppDatabase _db;

  Future<void> upsertSession(CachedWorkoutSessionsCompanion companion) {
    return _db
        .into(_db.cachedWorkoutSessions)
        .insertOnConflictUpdate(companion);
  }

  Future<void> upsertSet(CachedWorkoutSetsCompanion companion) {
    return _db.into(_db.cachedWorkoutSets).insertOnConflictUpdate(companion);
  }

  Future<void> deleteSet(String setId) {
    return (_db.delete(_db.cachedWorkoutSets)..where((t) => t.id.equals(setId)))
        .go();
  }

  Future<void> deleteSession(String sessionId) {
    return (_db.delete(_db.cachedWorkoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .go();
  }

  Future<CachedWorkoutSession?> getSession(String sessionId) {
    return (_db.select(_db.cachedWorkoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .getSingleOrNull();
  }

  Future<List<CachedWorkoutSet>> getSetsForSession(String sessionId) {
    return (_db.select(_db.cachedWorkoutSets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .get();
  }

  Future<List<CachedWorkoutSession>> getRecentSessions(
      {required String userId, int limit = 30}) {
    return (_db.select(_db.cachedWorkoutSessions)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> cacheRemoteSession(Map<String, dynamic> row) {
    return upsertSession(
      CachedWorkoutSessionsCompanion.insert(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        templateId: Value(row['template_id'] as String?),
        name: row['name'] as String,
        startedAt: DateTime.parse(row['started_at'] as String),
        completedAt: Value(
          row['completed_at'] == null
              ? null
              : DateTime.parse(row['completed_at'] as String),
        ),
        notes: Value(row['notes'] as String?),
        isDirty: const Value(false),
      ),
    );
  }
}
