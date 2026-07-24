import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.watch(supabaseClientProvider));
}

@riverpod
Future<UserProfile?> myProfile(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final result = await ref.watch(profileRepositoryProvider).getProfile(user.id);
  return result.match((failure) => throw failure, (profile) => profile);
}
