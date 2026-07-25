import '../../../../core/utils/result.dart';
import '../entities/workout_session.dart';

/// Offline-first: every method here writes to the local drift cache first
/// (so the UI never blocks on network) and enqueues the mutation for the
/// [SyncEngine] to reconcile with Supabase. `getHistory` reads from the
/// same local cache, refreshed opportunistically when online.
abstract interface class WorkoutSessionRepository {
  Future<Result<WorkoutSession>> startSession(
      {String? templateId, required String name});

  Future<Result<WorkoutSet>> logSet(WorkoutSet set);

  Future<Result<void>> deleteSet(String setId);

  Future<Result<WorkoutSession>> completeSession(String sessionId);

  Future<Result<WorkoutSession>> getSessionById(String sessionId);

  Future<Result<List<WorkoutSession>>> getHistory({int limit = 30});

  Future<Result<void>> deleteSession(String sessionId);

  /// True lifetime count of completed sessions (unlike [getHistory], which
  /// is capped for list-rendering performance) — used for profile stats.
  Future<Result<int>> getCompletedWorkoutCount();
}
