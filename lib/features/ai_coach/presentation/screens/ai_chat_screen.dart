import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../domain/entities/agent_type.dart';
import '../providers/chat_controller.dart';
import '../widgets/agent_selector.dart';
import '../widgets/chat_bubble.dart';

class AiChatScreen extends HookConsumerWidget {
  const AiChatScreen({required this.agentType, super.key});
  final AgentType agentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final messagesAsync = ref.watch(chatControllerProvider(agentType));
    final isSending = useState(false);

    Future<void> send() async {
      final text = textController.text;
      if (text.trim().isEmpty || isSending.value) return;
      textController.clear();
      isSending.value = true;
      await ref.read(chatControllerProvider(agentType).notifier).sendMessage(text);
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
      appBar: AppBar(title: Text(agentType.label)),
      body: Column(
        children: [
          AgentSelector(
            selected: agentType,
            onSelected: (agent) =>
                context.pushReplacement(RoutePaths.aiChat.replaceFirst(':agentType', agent.key)),
          ),
          const Divider(height: 1),
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
                        style: Theme.of(context).textTheme.bodyMedium,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(hintText: 'Ask your ${agentType.label.toLowerCase()}...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: isSending.value ? null : send,
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
