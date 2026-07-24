import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  @override
  Future<Result<NotificationPreferences>> getPreferences() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _client
          .from(AppConstants.tableNotificationPreferences)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return const Right(NotificationPreferences());
      return Right(_map(row));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<NotificationPreferences>> updatePreferences(NotificationPreferences prefs) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _client
          .from(AppConstants.tableNotificationPreferences)
          .upsert({
            'user_id': userId,
            'workout_reminders_enabled': prefs.workoutRemindersEnabled,
            'workout_reminder_time':
                '${prefs.workoutReminderHour.toString().padLeft(2, '0')}:${prefs.workoutReminderMinute.toString().padLeft(2, '0')}:00',
            'nutrition_reminders_enabled': prefs.nutritionRemindersEnabled,
            'nutrition_reminder_time':
                '${prefs.nutritionReminderHour.toString().padLeft(2, '0')}:${prefs.nutritionReminderMinute.toString().padLeft(2, '0')}:00',
            'recovery_reminders_enabled': prefs.recoveryRemindersEnabled,
            'ai_insights_enabled': prefs.aiInsightsEnabled,
          })
          .select()
          .single();
      return Right(_map(row));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<AiInsight>>> getInsights() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _client
          .from('ai_insights')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return Right(
        List<Map<String, dynamic>>.from(rows as List)
            .map(
              (row) => AiInsight(
                id: row['id'] as String,
                agentType: row['agent_type'] as String,
                title: row['title'] as String,
                body: row['body'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
                readAt: row['read_at'] == null ? null : DateTime.parse(row['read_at'] as String),
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markInsightRead(String insightId) async {
    try {
      await _client.from('ai_insights').update({'read_at': DateTime.now().toIso8601String()}).eq('id', insightId);
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  NotificationPreferences _map(Map<String, dynamic> row) {
    final workoutTime = (row['workout_reminder_time'] as String? ?? '18:00:00').split(':');
    final nutritionTime = (row['nutrition_reminder_time'] as String? ?? '12:00:00').split(':');
    return NotificationPreferences(
      workoutRemindersEnabled: row['workout_reminders_enabled'] as bool? ?? true,
      workoutReminderHour: int.parse(workoutTime[0]),
      workoutReminderMinute: int.parse(workoutTime[1]),
      nutritionRemindersEnabled: row['nutrition_reminders_enabled'] as bool? ?? true,
      nutritionReminderHour: int.parse(nutritionTime[0]),
      nutritionReminderMinute: int.parse(nutritionTime[1]),
      recoveryRemindersEnabled: row['recovery_reminders_enabled'] as bool? ?? true,
      aiInsightsEnabled: row['ai_insights_enabled'] as bool? ?? true,
    );
  }
}
