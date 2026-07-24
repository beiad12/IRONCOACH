import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

enum ChatRole { user, assistant, system }

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required ChatRole role,
    required String content,
    required DateTime createdAt,
    @Default(false) bool isStreaming,
  }) = _ChatMessage;
}

extension ChatRoleX on ChatRole {
  static ChatRole fromKey(String key) =>
      ChatRole.values.firstWhere((e) => e.name == key, orElse: () => ChatRole.user);
}
