import 'package:dio/dio.dart';

/// Thin client for the free, keyless Open Food Facts product API, used to
/// resolve a scanned barcode to nutrition facts before falling back to the
/// app's own `food_items` cache/manual entry.
class OpenFoodFactsDataSource {
  OpenFoodFactsDataSource(this._dio);

  final Dio _dio;
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  Future<Map<String, dynamic>?> fetchProduct(String barcode) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_baseUrl/$barcode.json',
      queryParameters: {
        'fields':
            'product_name,brands,serving_quantity,nutriments,image_front_url',
      },
    );

    final data = response.data;
    if (data == null || data['status'] != 1) return null;

    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    return {
      'barcode': barcode,
      'name': product['product_name'] as String? ?? 'Unknown product',
      'brand': product['brands'] as String?,
      'serving_size_g': (product['serving_quantity'] as num?)?.toDouble(),
      'calories_per_serving': (nutriments['energy-kcal_serving'] ??
                  nutriments['energy-kcal_100g'] as num?)
              ?.toDouble() ??
          0,
      'protein_g': (nutriments['proteins_serving'] ??
                  nutriments['proteins_100g'] as num?)
              ?.toDouble() ??
          0,
      'carbs_g': (nutriments['carbohydrates_serving'] ??
                  nutriments['carbohydrates_100g'] as num?)
              ?.toDouble() ??
          0,
      'fat_g': (nutriments['fat_serving'] ?? nutriments['fat_100g'] as num?)
              ?.toDouble() ??
          0,
      'fiber_g':
          (nutriments['fiber_serving'] ?? nutriments['fiber_100g'] as num?)
              ?.toDouble(),
      'sugar_g':
          (nutriments['sugars_serving'] ?? nutriments['sugars_100g'] as num?)
              ?.toDouble(),
      'sodium_mg':
          (nutriments['sodium_serving'] ?? nutriments['sodium_100g'] as num?)
              ?.toDouble(),
      'image_url': product['image_front_url'] as String?,
      'source': 'openfoodfacts',
    };
  }
}
