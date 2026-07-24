import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notification_providers.g.dart';

const _workoutReminderId = 1001;
const _nutritionReminderId = 1002;

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(ref.watch(supabaseClientProvider), () => ref.read(currentUserProvider)?.id);
}

@riverpod
Future<NotificationPreferences> notificationPreferences(Ref ref) async {
  final result = await ref.watch(notificationRepositoryProvider).getPreferences();
  return result.match((failure) => throw failure, (prefs) => prefs);
}

@riverpod
Future<List<AiInsight>> aiInsights(Ref ref) async {
  final result = await ref.watch(notificationRepositoryProvider).getInsights();
  return result.match((failure) => throw failure, (list) => list);
}

/// Persists preferences to Supabase, then (re)schedules the corresponding
/// local reminders so the two stay in lockstep — the alternative of
/// scheduling reminders only at app-launch would leave them stale after
/// any settings change.
class NotificationSettingsController {
  NotificationSettingsController(this._ref);
  final Ref _ref;

  Future<void> apply(NotificationPreferences prefs) async {
    await _ref.read(notificationRepositoryProvider).updatePreferences(prefs);
    final service = _ref.read(notificationServiceProvider);

    await service.cancel(_workoutReminderId);
    if (prefs.workoutRemindersEnabled) {
      await service.scheduleDaily(
        id: _workoutReminderId,
        channel: ReminderChannel.workout,
        title: 'Time to train 💪',
        body: "Don't break your streak — log today's workout.",
        time: ReminderTime(hour: prefs.workoutReminderHour, minute: prefs.workoutReminderMinute),
      );
    }

    await service.cancel(_nutritionReminderId);
    if (prefs.nutritionRemindersEnabled) {
      await service.scheduleDaily(
        id: _nutritionReminderId,
        channel: ReminderChannel.nutrition,
        title: 'Log your meals',
        body: 'Keep your nutrition tracking on point.',
        time: ReminderTime(hour: prefs.nutritionReminderHour, minute: prefs.nutritionReminderMinute),
      );
    }
  }
}

@riverpod
NotificationSettingsController notificationSettingsController(Ref ref) {
  return NotificationSettingsController(ref);
}
