import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/datasources/ai_remote_data_source.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/agent_type.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';

part 'ai_coach_providers.g.dart';

@Riverpod(keepAlive: true)
Dio aiDio(Ref ref) => Dio();

@Riverpod(keepAlive: true)
AiRepository aiRepository(Ref ref) {
  return AiRepositoryImpl(AiRemoteDataSource(ref.watch(supabaseClientProvider), ref.watch(aiDioProvider)));
}

@riverpod
Future<List<ChatMessage>> conversationHistory(Ref ref, AgentType agentType) async {
  final result = await ref.watch(aiRepositoryProvider).getConversationHistory(agentType);
  return result.match((failure) => throw failure, (messages) => messages);
}
