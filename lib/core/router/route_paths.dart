/// Central registry of every route path/name in the app. Keeping these as
/// constants (rather than magic strings scattered across `context.go(...)`
/// calls) makes renames and deep-link wiring safe.
abstract final class RoutePaths {
  // Auth
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String forgotPassword = '/forgot-password';

  // Shell tabs — Home / Train / Coach / Progress / Profile
  static const String home = '/home';
  static const String workouts = '/workouts';
  static const String aiCoach = '/ai-coach';
  static const String progress = '/progress';
  static const String profile = '/profile';

  // Workouts
  static const String exerciseLibrary = '/workouts/exercises';
  static const String exerciseDetail = '/workouts/exercises/:exerciseId';
  static const String workoutGenerator = '/workouts/generate';
  static const String workoutTemplateDetail = '/workouts/templates/:templateId';
  static const String activeWorkout = '/workouts/active/:sessionId';
  static const String workoutHistory = '/workouts/history';
  static const String workoutSummary = '/workouts/summary/:sessionId';

  // Nutrition — reached from a Home card / Profile menu, not a bottom tab
  static const String nutrition = '/nutrition';
  static const String logMeal = '/nutrition/log';
  static const String barcodeScanner = '/nutrition/scan';
  static const String mealDetail = '/nutrition/meals/:mealId';

  // Progress
  static const String logMeasurement = '/progress/measurements/log';
  static const String progressPhotos = '/progress/photos';
  static const String personalRecords = '/progress/records';

  // AI Coach
  static const String aiChat = '/ai-coach/chat/:agentType';

  // Community hub (Achievements/Challenges/Leaderboard/Friends)
  static const String community = '/community';
  static const String friends = '/social/friends';
  static const String leaderboard = '/social/leaderboard';
  static const String postDetail = '/social/posts/:postId';
  static const String achievements = '/achievements';
  static const String challenges = '/challenges';

  // Premium
  static const String premium = '/premium';

  // Settings
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit-profile';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/settings/notifications';
}
