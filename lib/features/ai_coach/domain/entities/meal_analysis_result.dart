import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_analysis_result.freezed.dart';
part 'meal_analysis_result.g.dart';

enum AnalysisConfidence { low, medium, high }

@freezed
class MealAnalysisResult with _$MealAnalysisResult {
  const factory MealAnalysisResult({
    required String foodName,
    required double estimatedCalories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required AnalysisConfidence confidence,
    required String notes,
  }) = _MealAnalysisResult;

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) => _$MealAnalysisResultFromJson(json);
}
