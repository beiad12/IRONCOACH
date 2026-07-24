import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_item.freezed.dart';

@freezed
class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String id,
    String? barcode,
    required String name,
    String? brand,
    double? servingSizeG,
    required double caloriesPerServing,
    @Default(0) double proteinG,
    @Default(0) double carbsG,
    @Default(0) double fatG,
    double? fiberG,
    double? sugarG,
    double? sodiumMg,
    String? imageUrl,
  }) = _FoodItem;
}
