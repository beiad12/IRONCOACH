import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../domain/entities/agent_type.dart';
import '../providers/chat_controller.dart';
import '../widgets/agent_selector.dart';
import '../widgets/chat_bubble.dart';

const _quickReplies = [
  "I'm feeling sore today",
  "How's my protein intake?",
  'Generate a new workout',
];

class AiChatScreen extends HookConsumerWidget {
  const AiChatScreen({required this.agentType, super.key});
  final AgentType agentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final messagesAsync = ref.watch(chatControllerProvider(agentType));
    final isSending = useState(false);

    Future<void> send([String? text]) async {
      final message = text ?? textController.text;
      if (message.trim().isEmpty || isSending.value) return;
      textController.clear();
      isSending.value = true;
      await ref.read(chatControllerProvider(agentType).notifier).sendMessage(message);
      isSending.value = false;
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.electricBlue, size: 16),
            ),
            const SizedBox(width: 10),
            Text(agentType.label),
          ],
        ),
      ),
      body: Column(
        children: [
          AgentSelector(
            selected: agentType,
            onSelected: (agent) =>
                context.pushReplacement(RoutePaths.aiChat.replaceFirst(':agentType', agent.key)),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          Expanded(
            child: AsyncValueWidget(
              value: messagesAsync,
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        agentType.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => ChatBubble(message: messages[i]),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => _QuickReplyChip(
                        label: _quickReplies[i],
                        onTap: isSending.value ? null : () => send(_quickReplies[i]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => send(),
                          decoration:
                              InputDecoration(hintText: 'Ask your ${agentType.label.toLowerCase()}...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.electricBlue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_forward, color: AppColors.onPrimaryGradient),
                          onPressed: isSending.value ? null : () => send(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
        ),
      ),
    );
  }
}
