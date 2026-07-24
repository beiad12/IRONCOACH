import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_plan.freezed.dart';
part 'daily_plan.g.dart';

@freezed
class WorkoutSuggestion with _$WorkoutSuggestion {
  const factory WorkoutSuggestion({
    required String focus,
    required int durationMinutes,
    required List<String> exercises,
  }) = _WorkoutSuggestion;

  factory WorkoutSuggestion.fromJson(Map<String, dynamic> json) => _$WorkoutSuggestionFromJson(json);
}

@freezed
class NutritionTargets with _$NutritionTargets {
  const factory NutritionTargets({
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
    required int waterMl,
  }) = _NutritionTargets;

  factory NutritionTargets.fromJson(Map<String, dynamic> json) => _$NutritionTargetsFromJson(json);
}

@freezed
class DailyPlan with _$DailyPlan {
  const factory DailyPlan({
    required String summary,
    required WorkoutSuggestion workoutSuggestion,
    required NutritionTargets nutritionTargets,
    required String recoveryTip,
  }) = _DailyPlan;

  factory DailyPlan.fromJson(Map<String, dynamic> json) => _$DailyPlanFromJson(json);
}
