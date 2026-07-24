import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool workoutRemindersEnabled,
    @Default(18) int workoutReminderHour,
    @Default(0) int workoutReminderMinute,
    @Default(true) bool nutritionRemindersEnabled,
    @Default(12) int nutritionReminderHour,
    @Default(0) int nutritionReminderMinute,
    @Default(true) bool recoveryRemindersEnabled,
    @Default(true) bool aiInsightsEnabled,
  }) = _NotificationPreferences;
}
