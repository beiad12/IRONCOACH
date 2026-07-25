import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/workout_session.dart';
import 'workout_providers.dart';

part 'active_workout_controller.g.dart';

/// Owns the in-progress [WorkoutSession]: adding/updating/completing sets
/// and finishing the workout. Backed by [WorkoutSessionRepository], which
/// already handles the offline-first local-write + sync-queue behavior, so
/// this controller only needs to keep its in-memory copy consistent and
/// re-emit it after each mutation.
@riverpod
class ActiveWorkoutController extends _$ActiveWorkoutController {
  final _uuid = const Uuid();

  @override
  Future<WorkoutSession> build(String sessionId) async {
    final result = await ref
        .read(workoutSessionRepositoryProvider)
        .getSessionById(sessionId);
    return result.match((failure) => throw failure, (session) => session);
  }

  Future<void> logSet({
    required String exerciseId,
    double? weightKg,
    int? reps,
    double? rpe,
    bool isWarmup = false,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final existingForExercise = current.setsByExercise[exerciseId] ?? const [];
    final newSet = WorkoutSet(
      id: _uuid.v4(),
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: existingForExercise.length + 1,
      weightKg: weightKg,
      reps: reps,
      rpe: rpe,
      isWarmup: isWarmup,
      isCompleted: true,
    );

    state = AsyncValue.data(current.copyWith(sets: [...current.sets, newSet]));
    await ref.read(workoutSessionRepositoryProvider).logSet(newSet);
  }

  Future<void> updateSet(WorkoutSet updated) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(
      current.copyWith(
        sets: [
          for (final s in current.sets)
            if (s.id == updated.id) updated else s
        ],
      ),
    );
    await ref.read(workoutSessionRepositoryProvider).logSet(updated);
  }

  Future<void> removeSet(String setId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(current.copyWith(
        sets: current.sets.where((s) => s.id != setId).toList()));
    await ref.read(workoutSessionRepositoryProvider).deleteSet(setId);
  }

  Future<WorkoutSession> finish() async {
    final result = await ref
        .read(workoutSessionRepositoryProvider)
        .completeSession(sessionId);
    return result.match((failure) => throw failure, (session) {
      state = AsyncValue.data(session);
      return session;
    });
  }
}
