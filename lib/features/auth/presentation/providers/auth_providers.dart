import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_use_cases.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(ref.watch(supabaseClientProvider));
}

/// Watched by [GoRouter]'s redirect logic and by any widget that needs to
/// react to sign-in/sign-out instantly.
@Riverpod(keepAlive: true)
Stream<AppUser?> authStateStream(Ref ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
}

@riverpod
AppUser? currentUser(Ref ref) {
  return ref.watch(authStateStreamProvider).valueOrNull;
}

@riverpod
SignInWithEmail signInWithEmail(Ref ref) => SignInWithEmail(ref.watch(authRepositoryProvider));

@riverpod
SignUpWithEmail signUpWithEmail(Ref ref) => SignUpWithEmail(ref.watch(authRepositoryProvider));

@riverpod
SignInWithGoogle signInWithGoogle(Ref ref) => SignInWithGoogle(ref.watch(authRepositoryProvider));

@riverpod
SignInWithApple signInWithApple(Ref ref) => SignInWithApple(ref.watch(authRepositoryProvider));

@riverpod
SendPasswordResetEmail sendPasswordResetEmail(Ref ref) =>
    SendPasswordResetEmail(ref.watch(authRepositoryProvider));

@riverpod
SignOut signOut(Ref ref) => SignOut(ref.watch(authRepositoryProvider));
