import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: message.content.isEmpty && message.isStreaming
            ? const _TypingDots()
            : Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 12,
      child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}
