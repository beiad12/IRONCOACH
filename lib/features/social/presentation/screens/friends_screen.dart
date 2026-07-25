import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/friend.dart';
import '../providers/social_providers.dart';
import '../widgets/friends_list.dart';

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
      final result =
          await ref.read(socialRepositoryProvider).searchUsers(query);
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
              decoration: const InputDecoration(
                  hintText: 'Search by username',
                  prefixIcon: Icon(Icons.search)),
              onChanged: search,
            ),
          ),
          if (searchResults.value.isNotEmpty)
            ...searchResults.value.map(
              (user) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.darkActivePill,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.username[0].toUpperCase())
                      : null,
                ),
                title: Text(user.displayName ?? user.username),
                subtitle: Text('@${user.username}'),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  onPressed: () async {
                    await ref
                        .read(socialRepositoryProvider)
                        .sendFriendRequest(user.userId);
                    ref.invalidate(friendshipsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend request sent')));
                    }
                  },
                ),
              ),
            ),
          const Divider(color: AppColors.darkBorder),
          Expanded(
            child: friendshipsAsync.when(
              data: (friendships) => ListView(
                padding: const EdgeInsets.all(16),
                children: [FriendsList(friendships: friendships)],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Something went wrong')),
            ),
          ),
        ],
      ),
    );
  }
}
