import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Domain representation of the signed-in user — a thin, UI/persistence
/// agnostic projection of Supabase's `User` + our `profiles` row. Keeping
/// this separate from `supabase_flutter`'s `User` means presentation code
/// never imports the Supabase SDK directly.
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required bool emailConfirmed,
    String? username,
    String? displayName,
    String? avatarUrl,
    @Default(false) bool onboardingCompleted,
  }) = _AppUser;
}
