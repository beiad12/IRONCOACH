import 'package:freezed_annotation/freezed_annotation.dart';

import 'food_item.dart';

part 'meal_entry.freezed.dart';

enum MealType { breakfast, lunch, dinner, snack }

@freezed
class MealEntryItem with _$MealEntryItem {
  const factory MealEntryItem({
    required String id,
    required FoodItem foodItem,
    required double quantity,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) = _MealEntryItem;
}

@freezed
class MealEntry with _$MealEntry {
  const factory MealEntry({
    required String id,
    required String userId,
    required MealType mealType,
    required DateTime loggedAt,
    String? photoUrl,
    String? notes,
    @Default([]) List<MealEntryItem> items,
  }) = _MealEntry;

  const MealEntry._();

  double get totalCalories => items.fold(0, (sum, i) => sum + i.calories);
  double get totalProteinG => items.fold(0, (sum, i) => sum + i.proteinG);
  double get totalCarbsG => items.fold(0, (sum, i) => sum + i.carbsG);
  double get totalFatG => items.fold(0, (sum, i) => sum + i.fatG);
}

extension MealTypeX on MealType {
  static MealType fromKey(String key) => MealType.values
      .firstWhere((e) => e.name == key, orElse: () => MealType.snack);

  String get label => name[0].toUpperCase() + name.substring(1);
}
