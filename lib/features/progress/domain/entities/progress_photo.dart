import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_photo.freezed.dart';

enum PhotoAngle { front, side, back }

@freezed
class ProgressPhoto with _$ProgressPhoto {
  const factory ProgressPhoto({
    required String id,
    required DateTime takenAt,
    required PhotoAngle angle,
    required String photoUrl,
    double? weightKg,
  }) = _ProgressPhoto;
}

extension PhotoAngleX on PhotoAngle {
  static PhotoAngle fromKey(String? key) =>
      PhotoAngle.values.firstWhere((e) => e.name == key, orElse: () => PhotoAngle.front);
}
