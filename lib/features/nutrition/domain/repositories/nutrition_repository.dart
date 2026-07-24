import '../../../../core/utils/result.dart';
import '../entities/food_item.dart';
import '../entities/meal_entry.dart';
import '../entities/nutrition_goals.dart';

abstract interface class NutritionRepository {
  Future<Result<FoodItem?>> lookupBarcode(String barcode);

  Future<Result<List<FoodItem>>> searchFoodItems(String query);

  Future<Result<FoodItem>> createManualFoodItem(FoodItem item);

  Future<Result<MealEntry>> logMeal({
    required MealType mealType,
    required List<MealEntryItem> items,
    DateTime? loggedAt,
    String? photoUrl,
    String? notes,
  });

  Future<Result<void>> deleteMeal(String mealEntryId);

  Future<Result<List<MealEntry>>> getMealsForDate(DateTime date);

  Future<Result<void>> logWater(int amountMl);

  Future<Result<int>> getWaterForDate(DateTime date);

  Future<Result<NutritionGoals>> getGoals();

  Future<Result<NutritionGoals>> updateGoals(NutritionGoals goals);
}
