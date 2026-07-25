// Integration test skeleton.
//
// Full end-to-end runs require a live (or local `supabase start`) Supabase
// project, since every provider chain bottoms out at `Supabase.instance.client`.
// Point `.env` at a disposable test project — never production — before
// running:
//
//   flutter test integration_test/app_test.dart
//
// This file covers only the unauthenticated golden path (splash -> login
// screen) so it stays runnable without seeded test-user credentials;
// feature-specific flows (logging a workout, sending a chat message) should
// get their own integration test files once fixtures / a seeded Supabase
// test project are wired into CI.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ironcoach/app.dart';
import 'package:ironcoach/core/config/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
        url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  });

  testWidgets('unauthenticated users land on the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IronCoachApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
