import 'dart:io';

import '../../../../core/utils/result.dart';
import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> getProfile(String userId);

  Future<Result<UserProfile>> updateProfile(UserProfile profile);

  Future<Result<String>> uploadAvatar({required String userId, required File file});
}
