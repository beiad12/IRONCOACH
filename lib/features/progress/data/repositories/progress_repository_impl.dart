import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/body_measurement.dart';
import '../../domain/entities/personal_record.dart';
import '../../domain/entities/progress_photo.dart';
import '../../domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;
  final _uuid = const Uuid();

  @override
  Future<Result<BodyMeasurement>> logMeasurement(
      BodyMeasurement measurement) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _client
          .from(AppConstants.tableBodyMeasurements)
          .insert({
            'user_id': userId,
            'measured_at': measurement.measuredAt.toIso8601String(),
            'weight_kg': measurement.weightKg,
            'body_fat_pct': measurement.bodyFatPct,
            'chest_cm': measurement.chestCm,
            'waist_cm': measurement.waistCm,
            'hips_cm': measurement.hipsCm,
            'bicep_cm': measurement.bicepCm,
            'thigh_cm': measurement.thighCm,
            'neck_cm': measurement.neckCm,
            'notes': measurement.notes,
          })
          .select()
          .single();
      return Right(_mapMeasurement(row));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<BodyMeasurement>>> getMeasurements(
      {int limit = 90}) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _client
          .from(AppConstants.tableBodyMeasurements)
          .select()
          .eq('user_id', userId)
          .order('measured_at', ascending: false)
          .limit(limit);
      return Right(List<Map<String, dynamic>>.from(rows as List)
          .map(_mapMeasurement)
          .toList());
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<ProgressPhoto>> uploadProgressPhoto({
    required File file,
    required PhotoAngle angle,
    double? weightKg,
  }) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final extension = file.path.split('.').last;
      final fileName = '${_uuid.v4()}.$extension';
      final path = '$userId/$fileName';

      await _client.storage
          .from(AppConstants.bucketProgressPhotos)
          .upload(path, file);
      final photoUrl = await _client.storage
          .from(AppConstants.bucketProgressPhotos)
          .createSignedUrl(path, 60 * 60 * 24 * 365);

      final row = await _client
          .from(AppConstants.tableProgressPhotos)
          .insert({
            'user_id': userId,
            'angle': angle.name,
            'photo_url': photoUrl,
            'weight_kg': weightKg,
          })
          .select()
          .single();

      return Right(_mapPhoto(row));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ProgressPhoto>>> getProgressPhotos() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _client
          .from(AppConstants.tableProgressPhotos)
          .select()
          .eq('user_id', userId)
          .order('taken_at', ascending: false);
      return Right(List<Map<String, dynamic>>.from(rows as List)
          .map(_mapPhoto)
          .toList());
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<PersonalRecord>>> getPersonalRecords() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _client
          .from(AppConstants.tablePersonalRecords)
          .select('*, exercises(name)')
          .eq('user_id', userId)
          .order('achieved_at', ascending: false);
      return Right(
        List<Map<String, dynamic>>.from(rows as List)
            .map(
              (row) => PersonalRecord(
                id: row['id'] as String,
                exerciseId: row['exercise_id'] as String,
                exerciseName: (row['exercises']
                        as Map<String, dynamic>?)?['name'] as String? ??
                    'Exercise',
                recordType: RecordTypeX.fromKey(row['record_type'] as String),
                value: (row['value'] as num).toDouble(),
                achievedAt: DateTime.parse(row['achieved_at'] as String),
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  BodyMeasurement _mapMeasurement(Map<String, dynamic> row) {
    return BodyMeasurement(
      id: row['id'] as String,
      measuredAt: DateTime.parse(row['measured_at'] as String),
      weightKg: (row['weight_kg'] as num?)?.toDouble(),
      bodyFatPct: (row['body_fat_pct'] as num?)?.toDouble(),
      chestCm: (row['chest_cm'] as num?)?.toDouble(),
      waistCm: (row['waist_cm'] as num?)?.toDouble(),
      hipsCm: (row['hips_cm'] as num?)?.toDouble(),
      bicepCm: (row['bicep_cm'] as num?)?.toDouble(),
      thighCm: (row['thigh_cm'] as num?)?.toDouble(),
      neckCm: (row['neck_cm'] as num?)?.toDouble(),
      notes: row['notes'] as String?,
    );
  }

  ProgressPhoto _mapPhoto(Map<String, dynamic> row) {
    return ProgressPhoto(
      id: row['id'] as String,
      takenAt: DateTime.parse(row['taken_at'] as String),
      angle: PhotoAngleX.fromKey(row['angle'] as String?),
      photoUrl: row['photo_url'] as String,
      weightKg: (row['weight_kg'] as num?)?.toDouble(),
    );
  }
}
