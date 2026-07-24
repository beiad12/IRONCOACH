import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

class WorkoutSessionRemoteDataSource {
  WorkoutSessionRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchRecentSessions({
    required String userId,
    int limit = 30,
  }) async {
    final rows = await _client
        .from(AppConstants.tableWorkoutSessions)
        .select()
        .eq('user_id', userId)
        .order('started_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchSetsForSession(String sessionId) async {
    final rows = await _client
        .from(AppConstants.tableWorkoutSets)
        .select()
        .eq('session_id', sessionId)
        .order('set_number');
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
