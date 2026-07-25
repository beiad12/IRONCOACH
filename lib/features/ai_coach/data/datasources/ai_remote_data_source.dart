import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../../../core/constants/app_constants.dart';

/// Talks to the three AI Edge Functions plus reads conversation history
/// directly from Postgres (cheaper than round-tripping through a function
/// for a plain `select`). The Mistral API itself is never called from the
/// client — see `supabase/functions/_shared/mistral.ts`.
class AiRemoteDataSource {
  AiRemoteDataSource(this._client, this._dio);

  final SupabaseClient _client;
  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchHistory(String agentType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final conversation = await _client
        .from(AppConstants.tableAiConversations)
        .select('id')
        .eq('user_id', userId)
        .eq('agent_type', agentType)
        .maybeSingle();

    if (conversation == null) return [];

    final rows = await _client
        .from(AppConstants.tableAiMessages)
        .select()
        .eq('conversation_id', conversation['id'] as String)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Streams raw text deltas by parsing the SSE response forwarded by the
  /// `ai-proxy` function (which itself forwards Mistral's stream verbatim).
  Stream<String> streamChat(
      {required String agentType, required String message}) async* {
    final session = _client.auth.currentSession;
    if (session == null) throw const HttpException('Not authenticated');

    final response = await _dio.post<ResponseBody>(
      '${Env.supabaseUrl}/functions/v1/${AppConstants.fnAiProxy}',
      data: {'agentType': agentType, 'message': message},
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': Env.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
      ),
    );

    final stream = response.data!.stream;
    var buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep any incomplete trailing line

      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final delta = json['choices']?[0]?['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        } on FormatException {
          // Partial JSON split across chunk boundaries; wait for more data.
        }
      }
    }
  }

  Future<Map<String, dynamic>> generateDailyPlan() async {
    final response =
        await _client.functions.invoke(AppConstants.fnDailyPlanner);
    _throwIfError(response);
    return (response.data as Map<String, dynamic>)['plan']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeMealPhoto({
    required String imageBase64,
    String? description,
    String? mealEntryId,
  }) async {
    final response = await _client.functions.invoke(
      AppConstants.fnMealAnalysis,
      body: {
        'imageBase64': imageBase64,
        if (description != null) 'description': description,
        if (mealEntryId != null) 'mealEntryId': mealEntryId,
      },
    );
    _throwIfError(response);
    return (response.data as Map<String, dynamic>)['result']
        as Map<String, dynamic>;
  }

  void _throwIfError(FunctionResponse response) {
    if (response.status != 200) {
      throw HttpException(
          'Edge function returned ${response.status}: ${response.data}');
    }
  }
}
