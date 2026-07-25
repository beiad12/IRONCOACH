import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/friend.dart';
import '../providers/social_providers.dart';

/// Shared friend/request list — used by the standalone [FriendsScreen]
/// (below its search box) and by the Community hub's Friends tab.
class FriendsList extends StatelessWidget {
  const FriendsList({required this.friendships, super.key});
  final List<Friendship> friendships;

  @override
  Widget build(BuildContext context) {
    if (friendships.isEmpty) {
      return const EmptyState(
          icon: Icons.group_outlined, title: 'No friends yet — search above');
    }

    final pending = friendships
        .where(
            (f) => f.status == FriendshipStatus.pending && f.isIncomingRequest)
        .toList();
    final accepted = friendships
        .where((f) => f.status == FriendshipStatus.accepted)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pending.isNotEmpty) ...[
          Text('Requests', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final f in pending)
            _FriendTile(friendship: f, showRequestActions: true),
          const SizedBox(height: 16),
        ],
        Text('Friends', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final f in accepted)
          _FriendTile(friendship: f, showRequestActions: false),
      ],
    );
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile(
      {required this.friendship, required this.showRequestActions});
  final Friendship friendship;
  final bool showRequestActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.darkActivePill,
            backgroundImage: friendship.otherUser.avatarUrl != null
                ? NetworkImage(friendship.otherUser.avatarUrl!)
                : null,
            child: friendship.otherUser.avatarUrl == null
                ? Text(friendship.otherUser.username[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendship.otherUser.displayName ??
                      friendship.otherUser.username,
                  style: const TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  '@${friendship.otherUser.username}',
                  style: const TextStyle(
                      color: AppColors.darkTextTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (showRequestActions)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.emerald),
                  onPressed: () async {
                    await ref
                        .read(socialRepositoryProvider)
                        .respondToFriendRequest(friendship.id, accept: true);
                    ref.invalidate(friendshipsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error),
                  onPressed: () async {
                    await ref
                        .read(socialRepositoryProvider)
                        .respondToFriendRequest(friendship.id, accept: false);
                    ref.invalidate(friendshipsProvider);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
