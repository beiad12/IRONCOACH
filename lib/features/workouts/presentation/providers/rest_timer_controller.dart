import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rest_timer_controller.g.dart';

class RestTimerState {
  const RestTimerState(
      {required this.totalSeconds,
      required this.remainingSeconds,
      required this.isRunning});

  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  double get progress =>
      totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;

  RestTimerState copyWith({int? remainingSeconds, bool? isRunning}) =>
      RestTimerState(
        totalSeconds: totalSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        isRunning: isRunning ?? this.isRunning,
      );
}

/// Simple countdown used between sets. Screen-scoped (not persisted) since
/// a rest timer restarting on app relaunch is acceptable UX.
@riverpod
class RestTimerController extends _$RestTimerController {
  Timer? _ticker;

  @override
  RestTimerState? build() => null;

  void start(int seconds) {
    _ticker?.cancel();
    state = RestTimerState(
        totalSeconds: seconds, remainingSeconds: seconds, isRunning: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current == null || current.remainingSeconds <= 1) {
        _ticker?.cancel();
        state = current?.copyWith(remainingSeconds: 0, isRunning: false);
        return;
      }
      state = current.copyWith(remainingSeconds: current.remainingSeconds - 1);
    });
  }

  void addSeconds(int delta) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
        remainingSeconds: (current.remainingSeconds + delta).clamp(0, 3600));
  }

  void skip() {
    _ticker?.cancel();
    final current = state;
    if (current != null)
      state = current.copyWith(remainingSeconds: 0, isRunning: false);
  }

  void dispose() {
    _ticker?.cancel();
  }
}
