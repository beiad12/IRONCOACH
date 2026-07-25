import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../datasources/nutrition_remote_data_source.dart';
import '../datasources/open_food_facts_data_source.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  NutritionRepositoryImpl({
    required NutritionRemoteDataSource remote,
    required OpenFoodFactsDataSource openFoodFacts,
    required String? Function() currentUserId,
  })  : _remote = remote,
        _openFoodFacts = openFoodFacts,
        _currentUserId = currentUserId;

  final NutritionRemoteDataSource _remote;
  final OpenFoodFactsDataSource _openFoodFacts;
  final String? Function() _currentUserId;

  @override
  Future<Result<FoodItem?>> lookupBarcode(String barcode) async {
    try {
      final cached = await _remote.findFoodByBarcode(barcode);
      if (cached != null) return Right(_mapFoodItem(cached));

      final fetched = await _openFoodFacts.fetchProduct(barcode);
      if (fetched == null) return const Right(null);

      final saved = await _remote.upsertFoodItem(fetched);
      return Right(_mapFoodItem(saved));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<FoodItem>>> searchFoodItems(String query) async {
    try {
      final rows = await _remote.searchFood(query);
      return Right(rows.map(_mapFoodItem).toList());
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<FoodItem>> createManualFoodItem(FoodItem item) async {
    try {
      final saved = await _remote.insertFoodItem({
        'name': item.name,
        'brand': item.brand,
        'serving_size_g': item.servingSizeG,
        'calories_per_serving': item.caloriesPerServing,
        'protein_g': item.proteinG,
        'carbs_g': item.carbsG,
        'fat_g': item.fatG,
        'source': 'manual',
      });
      return Right(_mapFoodItem(saved));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<MealEntry>> logMeal({
    required MealType mealType,
    required List<MealEntryItem> items,
    DateTime? loggedAt,
    String? photoUrl,
    String? notes,
  }) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());

    try {
      final entryRow = await _remote.insertMealEntry(
        userId: userId,
        mealType: mealType.name,
        loggedAt: loggedAt ?? DateTime.now(),
        photoUrl: photoUrl,
        notes: notes,
      );
      final entryId = entryRow['id'] as String;

      await _remote.insertMealEntryItems([
        for (final item in items)
          {
            'meal_entry_id': entryId,
            'food_item_id': item.foodItem.id,
            'quantity': item.quantity,
            'calories': item.calories,
            'protein_g': item.proteinG,
            'carbs_g': item.carbsG,
            'fat_g': item.fatG,
          },
      ]);

      return Right(
        MealEntry(
          id: entryId,
          userId: userId,
          mealType: mealType,
          loggedAt: DateTime.parse(entryRow['logged_at'] as String),
          photoUrl: photoUrl,
          notes: notes,
          items: items,
        ),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteMeal(String mealEntryId) async {
    try {
      await _remote.deleteMealEntry(mealEntryId);
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<List<MealEntry>>> getMealsForDate(DateTime date) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final rows = await _remote.fetchMealsForDate(userId: userId, date: date);
      return Right(rows.map((r) => _mapMealEntry(r, userId)).toList());
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> logWater(int amountMl) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      await _remote.insertWaterLog(userId: userId, amountMl: amountMl);
      return const Right(null);
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getWaterForDate(DateTime date) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      return Right(await _remote.fetchWaterForDate(userId: userId, date: date));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<NutritionGoals>> getGoals() async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _remote.fetchGoals(userId);
      if (row == null) {
        return const Right(NutritionGoals(
            calories: 2200, proteinG: 150, carbsG: 220, fatG: 70));
      }
      return Right(_mapGoals(row));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<NutritionGoals>> updateGoals(NutritionGoals goals) async {
    final userId = _currentUserId();
    if (userId == null) return const Left(Failure.unauthorized());
    try {
      final row = await _remote.upsertGoals({
        'user_id': userId,
        'calories': goals.calories,
        'protein_g': goals.proteinG,
        'carbs_g': goals.carbsG,
        'fat_g': goals.fatG,
        'water_ml': goals.waterMl,
        'is_ai_generated': goals.isAiGenerated,
      });
      return Right(_mapGoals(row));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  FoodItem _mapFoodItem(Map<String, dynamic> row) {
    return FoodItem(
      id: row['id'] as String,
      barcode: row['barcode'] as String?,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      servingSizeG: (row['serving_size_g'] as num?)?.toDouble(),
      caloriesPerServing: (row['calories_per_serving'] as num).toDouble(),
      proteinG: (row['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (row['carbs_g'] as num?)?.toDouble() ?? 0,
      fatG: (row['fat_g'] as num?)?.toDouble() ?? 0,
      fiberG: (row['fiber_g'] as num?)?.toDouble(),
      sugarG: (row['sugar_g'] as num?)?.toDouble(),
      sodiumMg: (row['sodium_mg'] as num?)?.toDouble(),
      imageUrl: row['image_url'] as String?,
    );
  }

  MealEntry _mapMealEntry(Map<String, dynamic> row, String userId) {
    final rawItems =
        List<Map<String, dynamic>>.from(row['meal_entry_items'] as List? ?? []);
    return MealEntry(
      id: row['id'] as String,
      userId: userId,
      mealType: MealTypeX.fromKey(row['meal_type'] as String),
      loggedAt: DateTime.parse(row['logged_at'] as String),
      photoUrl: row['photo_url'] as String?,
      notes: row['notes'] as String?,
      items: rawItems
          .map(
            (item) => MealEntryItem(
              id: item['id'] as String,
              foodItem:
                  _mapFoodItem(item['food_items'] as Map<String, dynamic>),
              quantity: (item['quantity'] as num).toDouble(),
              calories: (item['calories'] as num).toDouble(),
              proteinG: (item['protein_g'] as num).toDouble(),
              carbsG: (item['carbs_g'] as num).toDouble(),
              fatG: (item['fat_g'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }

  NutritionGoals _mapGoals(Map<String, dynamic> row) {
    return NutritionGoals(
      calories: row['calories'] as int,
      proteinG: row['protein_g'] as int,
      carbsG: row['carbs_g'] as int,
      fatG: row['fat_g'] as int,
      waterMl: row['water_ml'] as int? ?? 2500,
      isAiGenerated: row['is_ai_generated'] as bool? ?? false,
    );
  }
}
