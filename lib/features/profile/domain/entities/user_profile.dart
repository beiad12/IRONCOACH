import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

enum FitnessLevel { beginner, intermediate, advanced }

enum PrimaryGoal { loseFat, buildMuscle, maintain, improveEndurance, generalHealth }

enum MeasurementUnits { metric, imperial }

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    double? heightCm,
    double? weightKg,
    @Default(FitnessLevel.beginner) FitnessLevel fitnessLevel,
    PrimaryGoal? primaryGoal,
    @Default(MeasurementUnits.metric) MeasurementUnits units,
    @Default(true) bool isPublic,
  }) = _UserProfile;
}

extension FitnessLevelX on FitnessLevel {
  String get key => name;
  static FitnessLevel fromKey(String key) =>
      FitnessLevel.values.firstWhere((e) => e.name == key, orElse: () => FitnessLevel.beginner);
}

extension PrimaryGoalX on PrimaryGoal {
  String get key => switch (this) {
        PrimaryGoal.loseFat => 'lose_fat',
        PrimaryGoal.buildMuscle => 'build_muscle',
        PrimaryGoal.maintain => 'maintain',
        PrimaryGoal.improveEndurance => 'improve_endurance',
        PrimaryGoal.generalHealth => 'general_health',
      };

  static PrimaryGoal? fromKey(String? key) => switch (key) {
        'lose_fat' => PrimaryGoal.loseFat,
        'build_muscle' => PrimaryGoal.buildMuscle,
        'maintain' => PrimaryGoal.maintain,
        'improve_endurance' => PrimaryGoal.improveEndurance,
        'general_health' => PrimaryGoal.generalHealth,
        _ => null,
      };

  String get label => switch (this) {
        PrimaryGoal.loseFat => 'Lose fat',
        PrimaryGoal.buildMuscle => 'Build muscle',
        PrimaryGoal.maintain => 'Maintain',
        PrimaryGoal.improveEndurance => 'Improve endurance',
        PrimaryGoal.generalHealth => 'General health',
      };
}
