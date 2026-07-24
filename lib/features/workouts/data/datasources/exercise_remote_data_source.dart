import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

class ExerciseRemoteDataSource {
  ExerciseRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAll() async {
    final rows = await _client.from(AppConstants.tableExercises).select().order('name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Set<String>> fetchFavoriteIds(String userId) async {
    final rows = await _client
        .from(AppConstants.tableFavoriteExercises)
        .select('exercise_id')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows as List)
        .map((r) => r['exercise_id'] as String)
        .toSet();
  }

  Future<void> setFavorite(String userId, String exerciseId, {required bool isFavorite}) async {
    if (isFavorite) {
      await _client
          .from(AppConstants.tableFavoriteExercises)
          .upsert({'user_id': userId, 'exercise_id': exerciseId});
    } else {
      await _client
          .from(AppConstants.tableFavoriteExercises)
          .delete()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId);
    }
  }
}
