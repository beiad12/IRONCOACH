import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/shared_preferences_provider.dart';

part 'onboarding_providers.g.dart';

const _hasSeenOnboardingKey = 'has_seen_onboarding_carousel';

/// Whether the user has ever completed/skipped the marketing onboarding
/// carousel. Persisted locally (not per-account) — the carousel is shown
/// once per install/session-history, independent of which account
/// eventually signs in, matching the design's splash → onboarding → auth
/// flow (onboarding is pre-auth).
@Riverpod(keepAlive: true)
class HasSeenOnboarding extends _$HasSeenOnboarding {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> markSeen() async {
    await ref.read(sharedPreferencesProvider).setBool(_hasSeenOnboardingKey, true);
    state = true;
  }
}
