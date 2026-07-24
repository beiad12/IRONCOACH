import '../../../../core/utils/result.dart';
import '../entities/ai_insight.dart';
import '../entities/notification_preferences.dart';

abstract interface class NotificationRepository {
  Future<Result<NotificationPreferences>> getPreferences();

  Future<Result<NotificationPreferences>> updatePreferences(NotificationPreferences prefs);

  Future<Result<List<AiInsight>>> getInsights();

  Future<Result<void>> markInsightRead(String insightId);
}
