import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/shared_preferences_provider.dart';
import 'core/services/notification_service.dart';

/// Single entrypoint used by `main.dart` (and by flavored `main_*.dart`
/// files, if added later) so environment loading, Supabase init, and
/// crash/zone handling live in exactly one place.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: !Env.isProduction,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  FlutterError.onError = (details) {
    logger.e('Uncaught Flutter error', error: details.exception, stackTrace: details.stack);
  };

  final sharedPreferences = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
  );
  await container.read(notificationServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const IronCoachApp(),
    ),
  );
}
