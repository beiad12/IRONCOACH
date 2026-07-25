import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';

/// Contract for authentication, implemented against Supabase Auth in the
/// data layer. Use cases and presentation code depend only on this
/// interface, never on `supabase_flutter` types.
abstract interface class AuthRepository {
  Stream<AppUser?> watchAuthState();

  AppUser? get currentUser;

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// [username] is optional — when omitted, the `handle_new_user()` DB
  /// trigger assigns a default (`user_<id prefix>`) that the user can
  /// change later in Edit Profile, matching the design's minimal-friction
  /// signup (email + password only).
  Future<Result<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  });

  Future<Result<void>> signInWithGoogle();

  Future<Result<void>> signInWithApple();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> updatePassword(String newPassword);

  Future<Result<void>> signOut();

  Future<Result<void>> markOnboardingComplete();
}
