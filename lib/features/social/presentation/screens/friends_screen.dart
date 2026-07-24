import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/friend.dart';
import '../providers/social_providers.dart';

class FriendsScreen extends HookConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendshipsAsync = ref.watch(friendshipsProvider);
    final searchController = useTextEditingController();
    final searchResults = useState<List<FriendProfile>>([]);

    Future<void> search(String query) async {
      if (query.trim().isEmpty) {
        searchResults.value = [];
        return;
      }
      final result = await ref.read(socialRepositoryProvider).searchUsers(query);
      result.match((_) {}, (users) => searchResults.value = users);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(hintText: 'Search by username', prefixIcon: Icon(Icons.search)),
              onChanged: search,
            ),
          ),
          if (searchResults.value.isNotEmpty)
            ...searchResults.value.map(
              (user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Text(user.username[0].toUpperCase()) : null,
                ),
                title: Text(user.displayName ?? user.username),
                subtitle: Text('@${user.username}'),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  onPressed: () async {
                    await ref.read(socialRepositoryProvider).sendFriendRequest(user.userId);
                    ref.invalidate(friendshipsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Friend request sent')));
                    }
                  },
                ),
              ),
            ),
          const Divider(),
          Expanded(
            child: AsyncValueWidget(
              value: friendshipsAsync,
              onRetry: () => ref.invalidate(friendshipsProvider),
              data: (friendships) {
                final pending = friendships
                    .where((f) => f.status == FriendshipStatus.pending && f.isIncomingRequest)
                    .toList();
                final accepted = friendships.where((f) => f.status == FriendshipStatus.accepted).toList();

                if (friendships.isEmpty) {
                  return const EmptyState(icon: Icons.group_outlined, title: 'No friends yet — search above');
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      Text('Requests', style: Theme.of(context).textTheme.titleSmall),
                      for (final f in pending) _FriendTile(friendship: f, showRequestActions: true),
                      const SizedBox(height: 16),
                    ],
                    Text('Friends', style: Theme.of(context).textTheme.titleSmall),
                    for (final f in accepted) _FriendTile(friendship: f, showRequestActions: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile({required this.friendship, required this.showRequestActions});
  final Friendship friendship;
  final bool showRequestActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            friendship.otherUser.avatarUrl != null ? NetworkImage(friendship.otherUser.avatarUrl!) : null,
        child: friendship.otherUser.avatarUrl == null
            ? Text(friendship.otherUser.username[0].toUpperCase())
            : null,
      ),
      title: Text(friendship.otherUser.displayName ?? friendship.otherUser.username),
      subtitle: Text('@${friendship.otherUser.username}'),
      trailing: showRequestActions
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    await ref
                        .read(socialRepositoryProvider)
                        .respondToFriendRequest(friendship.id, accept: true);
                    ref.invalidate(friendshipsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await ref
                        .read(socialRepositoryProvider)
                        .respondToFriendRequest(friendship.id, accept: false);
                    ref.invalidate(friendshipsProvider);
                  },
                ),
              ],
            )
          : null,
    );
  }
}
