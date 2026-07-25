import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/local_db/app_database.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/repositories/workout_session_repository.dart';
import '../datasources/workout_session_local_data_source.dart';
import '../datasources/workout_session_remote_data_source.dart';

class WorkoutSessionRepositoryImpl implements WorkoutSessionRepository {
  WorkoutSessionRepositoryImpl({
    required WorkoutSessionLocalDataSource local,
    required WorkoutSessionRemoteDataSource remote,
    required AppDatabase db,
    required String? Function() currentUserId,
    Uuid? uuid,
  })  : _local = local,
        _remote = remote,
        _db = db,
        _currentUserId = currentUserId,
        _uuid = uuid ?? const Uuid();

  final WorkoutSessionLocalDataSource _local;
  final WorkoutSessionRemoteDataSource _remote;
  final AppDatabase _db;
  final String? Function() _currentUserId;
  final Uuid _uuid;

  @override
  Future<Result<WorkoutSession>> startSession(
      {String? templateId, required String name}) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());

    final id = _uuid.v4();
    final startedAt = DateTime.now();

    await _local.upsertSession(
      CachedWorkoutSessionsCompanion.insert(
        id: id,
        userId: userId,
        templateId: Value(templateId),
        name: name,
        startedAt: startedAt,
      ),
    );
    await _enqueue(
      table: 'workout_sessions',
      id: id,
      op: 'insert',
      payload: {
        'id': id,
        'user_id': userId,
        'template_id': templateId,
        'name': name,
        'started_at': startedAt.toIso8601String(),
      },
    );

    return Right(WorkoutSession(
        id: id,
        userId: userId,
        templateId: templateId,
        name: name,
        startedAt: startedAt));
  }

  @override
  Future<Result<WorkoutSet>> logSet(WorkoutSet set) async {
    final id = set.id.isEmpty ? _uuid.v4() : set.id;
    final resolved = set.copyWith(id: id);

    await _local.upsertSet(
      CachedWorkoutSetsCompanion.insert(
        id: id,
        sessionId: resolved.sessionId,
        exerciseId: resolved.exerciseId,
        setNumber: resolved.setNumber,
        weightKg: Value(resolved.weightKg),
        reps: Value(resolved.reps),
        rpe: Value(resolved.rpe),
        restSeconds: Value(resolved.restSeconds),
        isWarmup: Value(resolved.isWarmup),
        isCompleted: Value(resolved.isCompleted),
      ),
    );
    await _enqueue(
      table: 'workout_sets',
      id: id,
      op: 'insert',
      payload: {
        'id': id,
        'session_id': resolved.sessionId,
        'exercise_id': resolved.exerciseId,
        'set_number': resolved.setNumber,
        'weight_kg': resolved.weightKg,
        'reps': resolved.reps,
        'rpe': resolved.rpe,
        'rest_seconds': resolved.restSeconds,
        'is_warmup': resolved.isWarmup,
        'is_completed': resolved.isCompleted,
        if (resolved.isCompleted)
          'completed_at': DateTime.now().toIso8601String(),
      },
    );

    return Right(resolved);
  }

  @override
  Future<Result<void>> deleteSet(String setId) async {
    await _local.deleteSet(setId);
    await _enqueue(
        table: 'workout_sets', id: setId, op: 'delete', payload: {'id': setId});
    return const Right(null);
  }

  @override
  Future<Result<WorkoutSession>> completeSession(String sessionId) async {
    final row = await _local.getSession(sessionId);
    if (row == null) return const Left(Failure.notFound('Session not found'));

    final completedAt = DateTime.now();
    await _local.upsertSession(
      CachedWorkoutSessionsCompanion.insert(
        id: row.id,
        userId: row.userId,
        templateId: Value(row.templateId),
        name: row.name,
        startedAt: row.startedAt,
        completedAt: Value(completedAt),
      ),
    );
    await _enqueue(
      table: 'workout_sessions',
      id: sessionId,
      op: 'update',
      payload: {'id': sessionId, 'completed_at': completedAt.toIso8601String()},
    );

    return getSessionById(sessionId);
  }

  @override
  Future<Result<WorkoutSession>> getSessionById(String sessionId) async {
    final row = await _local.getSession(sessionId);
    if (row == null) return const Left(Failure.notFound('Session not found'));
    final sets = await _local.getSetsForSession(sessionId);
    return Right(_mapSession(row, sets));
  }

  @override
  Future<Result<List<WorkoutSession>>> getHistory({int limit = 30}) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());

    try {
      final remoteSessions =
          await _remote.fetchRecentSessions(userId: userId, limit: limit);
      for (final row in remoteSessions) {
        await _local.cacheRemoteSession(row);
      }
    } on Object {
      // Offline: serve whatever is cached locally below.
    }

    final cached = await _local.getRecentSessions(userId: userId, limit: limit);
    final sessions = <WorkoutSession>[];
    for (final row in cached) {
      final sets = await _local.getSetsForSession(row.id);
      sessions.add(_mapSession(row, sets));
    }
    return Right(sessions);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    await _local.deleteSession(sessionId);
    await _enqueue(
        table: 'workout_sessions',
        id: sessionId,
        op: 'delete',
        payload: {'id': sessionId});
    return const Right(null);
  }

  @override
  Future<Result<int>> getCompletedWorkoutCount() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      return Right(await _remote.countCompletedSessions(userId));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  Future<void> _enqueue({
    required String table,
    required String id,
    required String op,
    required Map<String, dynamic> payload,
  }) {
    return _db.enqueueSync(
      entityTable: table,
      entityId: id,
      operation: op,
      payloadJson: jsonEncode(payload),
    );
  }

  WorkoutSession _mapSession(
      CachedWorkoutSession row, List<CachedWorkoutSet> sets) {
    return WorkoutSession(
      id: row.id,
      userId: row.userId,
      templateId: row.templateId,
      name: row.name,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      notes: row.notes,
      totalVolumeKg: sets
          .where((s) => s.isCompleted && !s.isWarmup)
          .fold<double>(
              0, (sum, s) => sum + ((s.weightKg ?? 0) * (s.reps ?? 0))),
      sets: sets
          .map(
            (s) => WorkoutSet(
              id: s.id,
              sessionId: s.sessionId,
              exerciseId: s.exerciseId,
              setNumber: s.setNumber,
              weightKg: s.weightKg,
              reps: s.reps,
              rpe: s.rpe,
              restSeconds: s.restSeconds,
              isWarmup: s.isWarmup,
              isCompleted: s.isCompleted,
            ),
          )
          .toList(),
    );
  }
}
