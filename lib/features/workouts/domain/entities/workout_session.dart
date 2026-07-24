import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_session.freezed.dart';

@freezed
class WorkoutSet with _$WorkoutSet {
  const factory WorkoutSet({
    required String id,
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    double? weightKg,
    int? reps,
    double? rpe,
    int? restSeconds,
    @Default(false) bool isWarmup,
    @Default(false) bool isCompleted,
  }) = _WorkoutSet;
}

@freezed
class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required String userId,
    String? templateId,
    required String name,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,
    @Default(0) double totalVolumeKg,
    @Default([]) List<WorkoutSet> sets,
  }) = _WorkoutSession;

  const WorkoutSession._();

  bool get isActive => completedAt == null;

  Duration get elapsed => (completedAt ?? DateTime.now()).difference(startedAt);

  Map<String, List<WorkoutSet>> get setsByExercise {
    final map = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      (map[set.exerciseId] ??= []).add(set);
    }
    return map;
  }
}
