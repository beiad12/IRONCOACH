/// Central registry of every route path/name in the app. Keeping these as
/// constants (rather than magic strings scattered across `context.go(...)`
/// calls) makes renames and deep-link wiring safe.
abstract final class RoutePaths {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  // Shell tabs
  static const String home = '/home';
  static const String workouts = '/workouts';
  static const String nutrition = '/nutrition';
  static const String progress = '/progress';
  static const String aiCoach = '/ai-coach';
  static const String profile = '/profile';

  // Workouts
  static const String exerciseLibrary = '/workouts/exercises';
  static const String exerciseDetail = '/workouts/exercises/:exerciseId';
  static const String workoutGenerator = '/workouts/generate';
  static const String workoutTemplateDetail = '/workouts/templates/:templateId';
  static const String activeWorkout = '/workouts/active/:sessionId';
  static const String workoutHistory = '/workouts/history';
  static const String workoutSummary = '/workouts/summary/:sessionId';

  // Nutrition
  static const String logMeal = '/nutrition/log';
  static const String barcodeScanner = '/nutrition/scan';
  static const String mealDetail = '/nutrition/meals/:mealId';

  // Progress
  static const String logMeasurement = '/progress/measurements/log';
  static const String progressPhotos = '/progress/photos';
  static const String personalRecords = '/progress/records';

  // AI Coach
  static const String aiChat = '/ai-coach/chat/:agentType';

  // Social
  static const String friends = '/social/friends';
  static const String leaderboard = '/social/leaderboard';
  static const String postDetail = '/social/posts/:postId';

  // Gamification
  static const String achievements = '/achievements';
  static const String challenges = '/challenges';

  // Settings
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit-profile';
  static const String notificationSettings = '/settings/notifications';
}
