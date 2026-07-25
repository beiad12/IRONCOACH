import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/nutrition_remote_data_source.dart';
import '../../data/datasources/open_food_facts_data_source.dart';
import '../../data/repositories/nutrition_repository_impl.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/nutrition_repository.dart';

part 'nutrition_providers.g.dart';

@Riverpod(keepAlive: true)
Dio nutritionDio(Ref ref) => Dio();

@Riverpod(keepAlive: true)
NutritionRepository nutritionRepository(Ref ref) {
  return NutritionRepositoryImpl(
    remote: NutritionRemoteDataSource(ref.watch(supabaseClientProvider)),
    openFoodFacts: OpenFoodFactsDataSource(ref.watch(nutritionDioProvider)),
    currentUserId: () => ref.read(currentUserProvider)?.id,
  );
}

@riverpod
Future<List<MealEntry>> mealsForDate(Ref ref, DateTime date) async {
  final result = await ref.watch(nutritionRepositoryProvider).getMealsForDate(date);
  return result.match((failure) => throw failure, (meals) => meals);
}

@riverpod
Future<int> waterForDate(Ref ref, DateTime date) async {
  final result = await ref.watch(nutritionRepositoryProvider).getWaterForDate(date);
  return result.match((failure) => throw failure, (ml) => ml);
}

@riverpod
Future<NutritionGoals> nutritionGoals(Ref ref) async {
  final result = await ref.watch(nutritionRepositoryProvider).getGoals();
  return result.match((failure) => throw failure, (goals) => goals);
}

@riverpod
class DailyNutritionSummaryController extends _$DailyNutritionSummaryController {
  @override
  Future<DailyNutritionSummary> build(DateTime date) async {
    final meals = await ref.watch(mealsForDateProvider(date).future);
    final water = await ref.watch(waterForDateProvider(date).future);
    final goals = await ref.watch(nutritionGoalsProvider.future);

    return DailyNutritionSummary(
      calories: meals.fold(0, (sum, m) => sum + m.totalCalories),
      proteinG: meals.fold(0, (sum, m) => sum + m.totalProteinG),
      carbsG: meals.fold(0, (sum, m) => sum + m.totalCarbsG),
      fatG: meals.fold(0, (sum, m) => sum + m.totalFatG),
      waterMl: water,
      goals: goals,
    );
  }
}
