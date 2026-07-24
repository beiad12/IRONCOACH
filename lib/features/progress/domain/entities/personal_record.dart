import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_record.freezed.dart';

enum RecordType { oneRmEstimate, maxWeight, maxReps, maxVolume }

@freezed
class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    required String id,
    required String exerciseId,
    required String exerciseName,
    required RecordType recordType,
    required double value,
    required DateTime achievedAt,
  }) = _PersonalRecord;
}

extension RecordTypeX on RecordType {
  static RecordType fromKey(String key) => switch (key) {
        '1rm_estimate' => RecordType.oneRmEstimate,
        'max_weight' => RecordType.maxWeight,
        'max_reps' => RecordType.maxReps,
        'max_volume' => RecordType.maxVolume,
        _ => RecordType.maxWeight,
      };

  String get label => switch (this) {
        RecordType.oneRmEstimate => 'Estimated 1RM',
        RecordType.maxWeight => 'Max weight',
        RecordType.maxReps => 'Max reps',
        RecordType.maxVolume => 'Max volume',
      };
}
