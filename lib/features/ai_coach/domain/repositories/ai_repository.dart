import 'dart:io';

import '../../../../core/utils/result.dart';
import '../entities/agent_type.dart';
import '../entities/chat_message.dart';
import '../entities/daily_plan.dart';
import '../entities/meal_analysis_result.dart';

abstract interface class AiRepository {
  /// Loads the persisted conversation memory for [agentType] (up to the
  /// server-side history window used when building future prompts).
  Future<Result<List<ChatMessage>>> getConversationHistory(AgentType agentType);

  /// Streams the assistant's reply token-by-token via the `ai-proxy` edge
  /// function. The full reply is persisted server-side once the stream
  /// completes, so callers don't need to separately save it.
  Stream<String> streamMessage({required AgentType agentType, required String message});

  Future<Result<DailyPlan>> generateDailyPlan();

  Future<Result<MealAnalysisResult>> analyzeMealPhoto({
    required File imageFile,
    String? description,
    String? mealEntryId,
  });
}
