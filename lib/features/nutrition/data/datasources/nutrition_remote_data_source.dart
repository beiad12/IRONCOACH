import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

class NutritionRemoteDataSource {
  NutritionRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> findFoodByBarcode(String barcode) async {
    return _client
        .from(AppConstants.tableFoodItems)
        .select()
        .eq('barcode', barcode)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> searchFood(String query) async {
    final rows = await _client
        .from(AppConstants.tableFoodItems)
        .select()
        .ilike('name', '%$query%')
        .limit(25);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>> upsertFoodItem(Map<String, dynamic> data) async {
    return _client
        .from(AppConstants.tableFoodItems)
        .upsert(data, onConflict: 'barcode')
        .select()
        .single();
  }

  Future<Map<String, dynamic>> insertFoodItem(Map<String, dynamic> data) async {
    return _client
        .from(AppConstants.tableFoodItems)
        .insert(data)
        .select()
        .single();
  }

  Future<Map<String, dynamic>> insertMealEntry({
    required String userId,
    required String mealType,
    required DateTime loggedAt,
    String? photoUrl,
    String? notes,
  }) async {
    return _client
        .from(AppConstants.tableMealEntries)
        .insert({
          'user_id': userId,
          'meal_type': mealType,
          'logged_at': loggedAt.toIso8601String(),
          'photo_url': photoUrl,
          'notes': notes,
        })
        .select()
        .single();
  }

  Future<void> insertMealEntryItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    await _client.from(AppConstants.tableMealEntryItems).insert(items);
  }

  Future<void> deleteMealEntry(String id) async {
    await _client.from(AppConstants.tableMealEntries).delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchMealsForDate(
      {required String userId, required DateTime date}) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from(AppConstants.tableMealEntries)
        .select('*, meal_entry_items(*, food_items(*))')
        .eq('user_id', userId)
        .gte('logged_at', start.toIso8601String())
        .lt('logged_at', end.toIso8601String())
        .order('logged_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> insertWaterLog(
      {required String userId, required int amountMl}) async {
    await _client
        .from(AppConstants.tableWaterLogs)
        .insert({'user_id': userId, 'amount_ml': amountMl});
  }

  Future<int> fetchWaterForDate(
      {required String userId, required DateTime date}) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from(AppConstants.tableWaterLogs)
        .select('amount_ml')
        .eq('user_id', userId)
        .gte('logged_at', start.toIso8601String())
        .lt('logged_at', end.toIso8601String());
    return List<Map<String, dynamic>>.from(rows as List)
        .fold<int>(0, (sum, r) => sum + (r['amount_ml'] as int));
  }

  Future<Map<String, dynamic>?> fetchGoals(String userId) async {
    return _client
        .from(AppConstants.tableNutritionGoals)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> upsertGoals(Map<String, dynamic> data) async {
    return _client
        .from(AppConstants.tableNutritionGoals)
        .upsert(data)
        .select()
        .single();
  }
}
