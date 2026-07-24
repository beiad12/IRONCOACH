import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition_goals.freezed.dart';

@freezed
class NutritionGoals with _$NutritionGoals {
  const factory NutritionGoals({
    required int calories,
    required int proteinG,
    required int carbsG,
    required int fatG,
    @Default(2500) int waterMl,
    @Default(false) bool isAiGenerated,
  }) = _NutritionGoals;
}

@freezed
class DailyNutritionSummary with _$DailyNutritionSummary {
  const factory DailyNutritionSummary({
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required int waterMl,
    required NutritionGoals goals,
  }) = _DailyNutritionSummary;
}
