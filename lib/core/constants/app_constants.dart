/// App-wide constants that aren't secrets and don't belong in [Env].
abstract final class AppConstants {
  static const String appName = 'IronCoach';

  // Supabase table names — single source of truth to avoid typos scattered
  // across data sources.
  static const String tableProfiles = 'profiles';
  static const String tableExercises = 'exercises';
  static const String tableWorkoutTemplates = 'workout_templates';
  static const String tableWorkoutTemplateExercises =
      'workout_template_exercises';
  static const String tableWorkoutSessions = 'workout_sessions';
  static const String tableWorkoutSets = 'workout_sets';
  static const String tableFavoriteExercises = 'favorite_exercises';
  static const String tableFavoriteTemplates = 'favorite_templates';
  static const String tableMealEntries = 'meal_entries';
  static const String tableMealEntryItems = 'meal_entry_items';
  static const String tableFoodItems = 'food_items';
  static const String tableWaterLogs = 'water_logs';
  static const String tableNutritionGoals = 'nutrition_goals';
  static const String tableBodyMeasurements = 'body_measurements';
  static const String tableProgressPhotos = 'progress_photos';
  static const String tablePersonalRecords = 'personal_records';
  static const String tableAchievements = 'achievements';
  static const String tableUserAchievements = 'user_achievements';
  static const String tableUserLevels = 'user_levels';
  static const String tableStreaks = 'streaks';
  static const String tableChallenges = 'challenges';
  static const String tableChallengeParticipants = 'challenge_participants';
  static const String tableFriendships = 'friendships';
  static const String tablePosts = 'posts';
  static const String tablePostLikes = 'post_likes';
  static const String tablePostComments = 'post_comments';
  static const String tableAiConversations = 'ai_conversations';
  static const String tableAiMessages = 'ai_messages';
  static const String tableNotificationPreferences = 'notification_preferences';

  // Storage buckets
  static const String bucketAvatars = 'avatars';
  static const String bucketMealPhotos = 'meal-photos';
  static const String bucketProgressPhotos = 'progress-photos';
  static const String bucketPostMedia = 'post-media';

  // Edge functions
  static const String fnAiProxy = 'ai-proxy';
  static const String fnMealAnalysis = 'meal-analysis';
  static const String fnDailyPlanner = 'daily-planner';

  // Local (drift) sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int syncMaxRetries = 5;

  // Rest timer defaults
  static const int defaultRestSeconds = 90;
}
