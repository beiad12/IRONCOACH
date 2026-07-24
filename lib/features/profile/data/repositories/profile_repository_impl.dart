import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<UserProfile>> getProfile(String userId) => _guard(() async {
        final row = await _client
            .from(AppConstants.tableProfiles)
            .select()
            .eq('id', userId)
            .single();
        return _fromRow(row);
      });

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) => _guard(() async {
        final row = await _client
            .from(AppConstants.tableProfiles)
            .update({
              'username': profile.username,
              'display_name': profile.displayName,
              'bio': profile.bio,
              'height_cm': profile.heightCm,
              'weight_kg': profile.weightKg,
              'fitness_level': profile.fitnessLevel.key,
              'primary_goal': profile.primaryGoal?.key,
              'units': profile.units.name,
              'is_public': profile.isPublic,
            })
            .eq('id', profile.id)
            .select()
            .single();
        return _fromRow(row);
      });

  @override
  Future<Result<String>> uploadAvatar({required String userId, required File file}) =>
      _guard(() async {
        final extension = file.path.split('.').last;
        final path = '$userId/avatar.$extension';
        await _client.storage.from(AppConstants.bucketAvatars).upload(
              path,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
        final publicUrl = _client.storage.from(AppConstants.bucketAvatars).getPublicUrl(path);
        await _client.from(AppConstants.tableProfiles).update({'avatar_url': publicUrl}).eq('id', userId);
        return publicUrl;
      });

  UserProfile _fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      username: row['username'] as String,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      heightCm: (row['height_cm'] as num?)?.toDouble(),
      weightKg: (row['weight_kg'] as num?)?.toDouble(),
      fitnessLevel: FitnessLevelX.fromKey(row['fitness_level'] as String? ?? 'beginner'),
      primaryGoal: PrimaryGoalX.fromKey(row['primary_goal'] as String?),
      units: (row['units'] as String? ?? 'metric') == 'imperial'
          ? MeasurementUnits.imperial
          : MeasurementUnits.metric,
      isPublic: row['is_public'] as bool? ?? true,
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on PostgrestException catch (e) {
      return Left(Failure.server(message: e.message));
    } on StorageException catch (e) {
      return Left(Failure.server(message: e.message));
    } on Object catch (e) {
      return Left(Failure.unexpected(e.toString()));
    }
  }
}
