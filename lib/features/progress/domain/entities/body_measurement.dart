import 'package:freezed_annotation/freezed_annotation.dart';

part 'body_measurement.freezed.dart';

@freezed
class BodyMeasurement with _$BodyMeasurement {
  const factory BodyMeasurement({
    required String id,
    required DateTime measuredAt,
    double? weightKg,
    double? bodyFatPct,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bicepCm,
    double? thighCm,
    double? neckCm,
    String? notes,
  }) = _BodyMeasurement;
}
