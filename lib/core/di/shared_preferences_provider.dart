import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// Overridden in `bootstrap.dart` with a real, already-loaded instance
/// before the `ProviderScope` is created, so any provider that needs
/// synchronous local key/value storage (e.g. "has the user seen the
/// onboarding carousel") can `ref.read` it directly instead of dealing
/// with a `Future`.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in bootstrap.dart');
}
