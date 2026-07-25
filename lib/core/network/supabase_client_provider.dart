import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

/// Global [SupabaseClient] instance, initialized once in `bootstrap.dart`
/// via `Supabase.initialize` and exposed to the rest of the app through
/// Riverpod so every data source depends on this provider rather than the
/// `Supabase.instance` singleton directly (keeps repositories testable).
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
GoTrueClient supabaseAuth(Ref ref) => ref.watch(supabaseClientProvider).auth;

/// Stream of auth state changes — the single source of truth for whether
/// the user is signed in, consumed by the router's redirect logic and the
/// auth feature's session providers.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(supabaseAuthProvider).onAuthStateChange;
