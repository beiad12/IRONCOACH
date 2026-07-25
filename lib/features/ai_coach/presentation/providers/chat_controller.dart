import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/agent_type.dart';
import '../../domain/entities/chat_message.dart';
import 'ai_coach_providers.dart';

part 'chat_controller.g.dart';

/// Per-agent chat state: seeds from persisted conversation history, then
/// manages the optimistic user-message + streaming-assistant-message
/// lifecycle for new turns. The `ai-proxy` edge function persists both
/// sides server-side, so this controller's job is purely the in-memory
/// view during an active session — a fresh app launch re-seeds from
/// [conversationHistoryProvider].
@riverpod
class ChatController extends _$ChatController {
  final _uuid = const Uuid();

  @override
  Future<List<ChatMessage>> build(AgentType agentType) {
    return ref.watch(conversationHistoryProvider(agentType).future);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state.valueOrNull ?? [];
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    final assistantId = _uuid.v4();
    final placeholder = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );

    state = AsyncValue.data([...current, userMessage, placeholder]);

    final buffer = StringBuffer();
    try {
      await for (final delta in ref
          .read(aiRepositoryProvider)
          .streamMessage(agentType: agentType, message: trimmed)) {
        buffer.write(delta);
        _updateAssistantMessage(assistantId, buffer.toString(),
            isStreaming: true);
      }
      _updateAssistantMessage(assistantId, buffer.toString(),
          isStreaming: false);
    } on Object {
      _updateAssistantMessage(
        assistantId,
        buffer.isEmpty
            ? "Sorry, I couldn't respond just now. Please try again."
            : buffer.toString(),
        isStreaming: false,
      );
    }
  }

  void _updateAssistantMessage(String id, String content,
      {required bool isStreaming}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data([
      for (final m in current)
        if (m.id == id)
          m.copyWith(content: content, isStreaming: isStreaming)
        else
          m,
    ]);
  }
}
