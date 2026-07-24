import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../providers/social_providers.dart';

class PostDetailScreen extends HookConsumerWidget {
  const PostDetailScreen({required this.postId, super.key});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(postCommentsProvider(postId));
    final commentController = useTextEditingController();
    final dateFormat = DateFormat('MMM d, h:mm a');

    Future<void> submitComment() async {
      final text = commentController.text.trim();
      if (text.isEmpty) return;
      commentController.clear();
      await ref.read(socialRepositoryProvider).addComment(postId, text);
      ref.invalidate(postCommentsProvider(postId));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueWidget(
              value: commentsAsync,
              onRetry: () => ref.invalidate(postCommentsProvider(postId)),
              data: (comments) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, i) {
                  final comment = comments[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(comment.author.username[0].toUpperCase())),
                    title: Text(comment.author.displayName ?? comment.author.username),
                    subtitle: Text(comment.body),
                    trailing: Text(
                      dateFormat.format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
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
                      controller: commentController,
                      decoration: const InputDecoration(hintText: 'Add a comment...'),
                      onSubmitted: (_) => submitComment(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: submitComment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
