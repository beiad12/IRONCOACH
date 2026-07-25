import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../domain/entities/notification_preferences.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncValueWidget(
        value: prefsAsync,
        onRetry: () => ref.invalidate(notificationPreferencesProvider),
        data: (prefs) => _PreferencesFormStateful(initial: prefs),
      ),
    );
  }
}

class _PreferencesFormStateful extends ConsumerStatefulWidget {
  const _PreferencesFormStateful({required this.initial});
  final NotificationPreferences initial;

  @override
  ConsumerState<_PreferencesFormStateful> createState() =>
      _PreferencesFormStatefulState();
}

class _PreferencesFormStatefulState
    extends ConsumerState<_PreferencesFormStateful> {
  late NotificationPreferences prefs = widget.initial;

  Future<void> _update(NotificationPreferences updated) async {
    setState(() => prefs = updated);
    await ref.read(notificationSettingsControllerProvider).apply(updated);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Workout reminders'),
          subtitle: Text(_formatTime(
              prefs.workoutReminderHour, prefs.workoutReminderMinute)),
          value: prefs.workoutRemindersEnabled,
          onChanged: (v) => _update(prefs.copyWith(workoutRemindersEnabled: v)),
          secondary: prefs.workoutRemindersEnabled
              ? IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(
                    initialHour: prefs.workoutReminderHour,
                    initialMinute: prefs.workoutReminderMinute,
                    onPicked: (h, m) => _update(prefs.copyWith(
                        workoutReminderHour: h, workoutReminderMinute: m)),
                  ),
                )
              : null,
        ),
        SwitchListTile(
          title: const Text('Nutrition reminders'),
          subtitle: Text(_formatTime(
              prefs.nutritionReminderHour, prefs.nutritionReminderMinute)),
          value: prefs.nutritionRemindersEnabled,
          onChanged: (v) =>
              _update(prefs.copyWith(nutritionRemindersEnabled: v)),
          secondary: prefs.nutritionRemindersEnabled
              ? IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(
                    initialHour: prefs.nutritionReminderHour,
                    initialMinute: prefs.nutritionReminderMinute,
                    onPicked: (h, m) => _update(prefs.copyWith(
                        nutritionReminderHour: h, nutritionReminderMinute: m)),
                  ),
                )
              : null,
        ),
        SwitchListTile(
          title: const Text('Recovery reminders'),
          value: prefs.recoveryRemindersEnabled,
          onChanged: (v) =>
              _update(prefs.copyWith(recoveryRemindersEnabled: v)),
        ),
        SwitchListTile(
          title: const Text('AI insights'),
          subtitle: const Text('Proactive tips from your AI coaches'),
          value: prefs.aiInsightsEnabled,
          onChanged: (v) => _update(prefs.copyWith(aiInsightsEnabled: v)),
        ),
      ],
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime({
    required int initialHour,
    required int initialMinute,
    required void Function(int hour, int minute) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked != null) onPicked(picked.hour, picked.minute);
  }
}
