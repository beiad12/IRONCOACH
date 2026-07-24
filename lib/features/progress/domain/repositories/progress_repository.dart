import 'dart:io';

import '../../../../core/utils/result.dart';
import '../entities/body_measurement.dart';
import '../entities/personal_record.dart';
import '../entities/progress_photo.dart';

abstract interface class ProgressRepository {
  Future<Result<BodyMeasurement>> logMeasurement(BodyMeasurement measurement);

  Future<Result<List<BodyMeasurement>>> getMeasurements({int limit = 90});

  Future<Result<ProgressPhoto>> uploadProgressPhoto({
    required File file,
    required PhotoAngle angle,
    double? weightKg,
  });

  Future<Result<List<ProgressPhoto>>> getProgressPhotos();

  Future<Result<List<PersonalRecord>>> getPersonalRecords();
}
