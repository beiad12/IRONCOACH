import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../features/ai_coach/domain/entities/agent_type.dart';
import '../../features/ai_coach/presentation/screens/ai_chat_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/onboarding_providers.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/gamification/presentation/screens/achievements_screen.dart';
import '../../features/gamification/presentation/screens/challenges_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/settings_screen.dart';
import '../../features/nutrition/presentation/screens/barcode_scanner_screen.dart';
import '../../features/nutrition/presentation/screens/log_meal_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/premium_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/log_measurement_screen.dart';
import '../../features/progress/presentation/screens/personal_records_screen.dart';
import '../../features/progress/presentation/screens/progress_photos_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/social/presentation/screens/community_screen.dart';
import '../../features/social/presentation/screens/friends_screen.dart';
import '../../features/social/presentation/screens/leaderboard_screen.dart';
import '../../features/social/presentation/screens/post_detail_screen.dart';
import '../../features/workouts/presentation/screens/active_workout_screen.dart';
import '../../features/workouts/presentation/screens/exercise_detail_screen.dart';
import '../../features/workouts/presentation/screens/exercise_library_screen.dart';
import '../../features/workouts/presentation/screens/workout_generator_screen.dart';
import '../../features/workouts/presentation/screens/workout_history_screen.dart';
import '../../features/workouts/presentation/screens/workout_summary_screen.dart';
import '../../features/workouts/presentation/screens/workout_template_detail_screen.dart';
import '../../features/workouts/presentation/screens/workouts_screen.dart';
import '../navigation/main_shell.dart';
import 'route_paths.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final authStateAsync = ref.watch(authStateStreamProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final preAuthScreen = state.matchedLocation == RoutePaths.onboarding ||
          state.matchedLocation == RoutePaths.auth ||
          state.matchedLocation == RoutePaths.forgotPassword;
      final atSplash = state.matchedLocation == RoutePaths.splash;
      final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);

      return authStateAsync.when(
        data: (session) {
          final isAuthed = session != null;
          if (isAuthed) {
            return (preAuthScreen || atSplash) ? RoutePaths.home : null;
          }
          if (atSplash) {
            return hasSeenOnboarding ? RoutePaths.auth : RoutePaths.onboarding;
          }
          if (!preAuthScreen) {
            return hasSeenOnboarding ? RoutePaths.auth : RoutePaths.onboarding;
          }
          return null;
        },
        loading: () => atSplash ? null : RoutePaths.splash,
        error: (_, __) => RoutePaths.auth,
      );
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RoutePaths.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: RoutePaths.auth, builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: RoutePaths.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.workouts,
              builder: (_, __) => const WorkoutsScreen(),
              routes: [
                GoRoute(
                  path: 'exercises',
                  builder: (_, __) => const ExerciseLibraryScreen(),
                  routes: [
                    GoRoute(
                      path: ':exerciseId',
                      builder: (_, state) =>
                          ExerciseDetailScreen(exerciseId: state.pathParameters['exerciseId']!),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'generate',
                  builder: (_, __) => const WorkoutGeneratorScreen(),
                ),
                GoRoute(
                  path: 'templates/:templateId',
                  builder: (_, state) => WorkoutTemplateDetailScreen(
                    templateId: state.pathParameters['templateId']!,
                  ),
                ),
                GoRoute(
                  path: 'active/:sessionId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, state) =>
                      ActiveWorkoutScreen(sessionId: state.pathParameters['sessionId']!),
                ),
                GoRoute(
                  path: 'summary/:sessionId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, state) =>
                      WorkoutSummaryScreen(sessionId: state.pathParameters['sessionId']!),
                ),
                GoRoute(
                  path: 'history',
                  builder: (_, __) => const WorkoutHistoryScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.aiCoach,
              builder: (_, __) => const AiChatScreen(agentType: AgentType.workoutCoach),
              routes: [
                GoRoute(
                  path: 'chat/:agentType',
                  builder: (_, state) => AiChatScreen(
                    agentType: AgentType.fromKey(state.pathParameters['agentType']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.progress,
              builder: (_, __) => const ProgressScreen(),
              routes: [
                GoRoute(
                  path: 'measurements/log',
                  builder: (_, __) => const LogMeasurementScreen(),
                ),
                GoRoute(path: 'photos', builder: (_, __) => const ProgressPhotosScreen()),
                GoRoute(path: 'records', builder: (_, __) => const PersonalRecordsScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RoutePaths.profile,
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'edit-profile', builder: (_, __) => const EditProfileScreen()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: RoutePaths.nutrition,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NutritionScreen(),
        routes: [
          GoRoute(path: 'log', builder: (_, __) => const LogMealScreen()),
          GoRoute(path: 'scan', builder: (_, __) => const BarcodeScannerScreen()),
        ],
      ),
      GoRoute(
        path: RoutePaths.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (_, __) => const NotificationSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.community,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CommunityScreen(),
      ),
      GoRoute(
        path: RoutePaths.premium,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const PremiumScreen(),
      ),
      GoRoute(
        path: RoutePaths.achievements,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: RoutePaths.challenges,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ChallengesScreen(),
      ),
      GoRoute(
        path: RoutePaths.friends,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const FriendsScreen(),
      ),
      GoRoute(
        path: RoutePaths.leaderboard,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.postDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => PostDetailScreen(postId: state.pathParameters['postId']!),
      ),
    ],
  );
}

/// Bridges a Riverpod-watched async auth stream to GoRouter's
/// [Listenable]-based `refreshListenable`, so the router re-evaluates
/// `redirect` every time auth state (or the onboarding-seen flag) changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref
      ..listen(authStateStreamProvider, (_, __) => notifyListeners())
      ..listen(hasSeenOnboardingProvider, (_, __) => notifyListeners())
      ..onDispose(dispose);
  }
}
