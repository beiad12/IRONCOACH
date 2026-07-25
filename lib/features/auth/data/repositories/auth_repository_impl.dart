import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Stream<AppUser?> watchAuthState() {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      return _mapUserWithProfile(user);
    });
  }

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
        final response = await _client.auth.signInWithPassword(email: email, password: password);
        final user = response.user;
        if (user == null) throw const UnauthorizedException('Sign-in failed');
        return _mapUserWithProfile(user);
      });

  @override
  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) => _guard(() async {
        final response = await _client.auth.signUp(
          email: email,
          password: password,
          data: username == null ? null : {'username': username},
        );
        final user = response.user;
        if (user == null) throw const UnauthorizedException('Sign-up failed');
        return _mapUserWithProfile(user);
      });

  @override
  Future<Result<void>> signInWithGoogle() => _guard(() async {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.ironcoach.app://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      });

  @override
  Future<Result<void>> signInWithApple() => _guard(() async {
        await _client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: 'io.ironcoach.app://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      });

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) => _guard(() async {
        await _client.auth.resetPasswordForEmail(
          email,
          redirectTo: 'io.ironcoach.app://reset-password-callback',
        );
      });

  @override
  Future<Result<void>> updatePassword(String newPassword) => _guard(() async {
        await _client.auth.updateUser(UserAttributes(password: newPassword));
      });

  @override
  Future<Result<void>> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<Result<void>> markOnboardingComplete() => _guard(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) throw const UnauthorizedException();
        await _client.from(AppConstants.tableProfiles).update({
          'onboarding_completed_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      });

  AppUser _mapUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  Future<AppUser> _mapUserWithProfile(User user) async {
    final base = _mapUser(user);
    try {
      final profile = await _client
          .from(AppConstants.tableProfiles)
          .select('username, display_name, avatar_url, onboarding_completed_at')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return base;

      return base.copyWith(
        username: profile['username'] as String?,
        displayName: profile['display_name'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        onboardingCompleted: profile['onboarding_completed_at'] != null,
      );
    } on Object {
      return base;
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      if (e.statusCode == '400' || e.statusCode == '422') {
        return Left(Failure.validation(e.message));
      }
      return Left(Failure.unauthorized(e.message));
    } on UnauthorizedException catch (e) {
      return Left(Failure.unauthorized(e.message));
    } on PostgrestException catch (e) {
      return Left(Failure.server(message: e.message, statusCode: int.tryParse(e.code ?? '')));
    } on Object catch (e) {
      return Left(Failure.unexpected(e.toString()));
    }
  }
}
