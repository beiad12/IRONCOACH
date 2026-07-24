import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_insight.freezed.dart';

@freezed
class AiInsight with _$AiInsight {
  const factory AiInsight({
    required String id,
    required String agentType,
    required String title,
    required String body,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _AiInsight;
}
