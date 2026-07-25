import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/agent_type.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/meal_analysis_result.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_data_source.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._remote);

  final AiRemoteDataSource _remote;
  final _uuid = const Uuid();

  @override
  Future<Result<List<ChatMessage>>> getConversationHistory(
      AgentType agentType) async {
    try {
      final rows = await _remote.fetchHistory(agentType.key);
      return Right(
        rows
            .map(
              (row) => ChatMessage(
                id: row['id'] as String,
                role: ChatRoleX.fromKey(row['role'] as String),
                content: row['content'] as String,
                createdAt: DateTime.parse(row['created_at'] as String),
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Stream<String> streamMessage(
      {required AgentType agentType, required String message}) {
    return _remote.streamChat(agentType: agentType.key, message: message);
  }

  @override
  Future<Result<DailyPlan>> generateDailyPlan() async {
    try {
      final json = await _remote.generateDailyPlan();
      return Right(DailyPlan.fromJson(json));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  @override
  Future<Result<MealAnalysisResult>> analyzeMealPhoto({
    required File imageFile,
    String? description,
    String? mealEntryId,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final json = await _remote.analyzeMealPhoto(
        imageBase64: base64Image,
        description: description,
        mealEntryId: mealEntryId,
      );
      return Right(MealAnalysisResult.fromJson(json));
    } on Object catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  String newLocalMessageId() => _uuid.v4();
}
