import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../gamification/presentation/widgets/achievements_grid.dart';
import '../../../gamification/presentation/widgets/challenges_list.dart';
import '../providers/social_providers.dart';
import '../widgets/friends_list.dart';
import '../widgets/leaderboard_list.dart';

enum _CommunityTab { achievements, challenges, leaderboard, friends }

/// Consolidates Achievements, Challenges, Leaderboard, and Friends into one
/// hub, matching the design's Community screen — each tab reuses the same
/// widgets/providers as the standalone screens (still reachable directly
/// for deep links), so there's a single source of truth for the UI.
class CommunityScreen extends HookConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(_CommunityTab.achievements);

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedTabs<_CommunityTab>(
            selected: tab.value,
            scrollable: true,
            onChanged: (v) => tab.value = v,
            options: const [
              SegmentedTabOption(value: _CommunityTab.achievements, label: 'Achievements'),
              SegmentedTabOption(value: _CommunityTab.challenges, label: 'Challenges'),
              SegmentedTabOption(value: _CommunityTab.leaderboard, label: 'Leaderboard'),
              SegmentedTabOption(value: _CommunityTab.friends, label: 'Friends'),
            ],
          ),
          const SizedBox(height: 20),
          switch (tab.value) {
            _CommunityTab.achievements => Consumer(
                builder: (context, ref, _) => AsyncValueWidget(
                  value: ref.watch(achievementsProvider),
                  onRetry: () => ref.invalidate(achievementsProvider),
                  data: (items) => AchievementsGrid(achievements: items),
                ),
              ),
            _CommunityTab.challenges => Consumer(
                builder: (context, ref, _) => AsyncValueWidget(
                  value: ref.watch(challengesProvider),
                  onRetry: () => ref.invalidate(challengesProvider),
                  data: (items) => ChallengesList(challenges: items),
                ),
              ),
            _CommunityTab.leaderboard => Consumer(
                builder: (context, ref, _) => AsyncValueWidget(
                  value: ref.watch(leaderboardProvider),
                  onRetry: () => ref.invalidate(leaderboardProvider),
                  data: (items) => LeaderboardList(entries: items),
                ),
              ),
            _CommunityTab.friends => Consumer(
                builder: (context, ref, _) => AsyncValueWidget(
                  value: ref.watch(friendshipsProvider),
                  onRetry: () => ref.invalidate(friendshipsProvider),
                  data: (items) => FriendsList(friendships: items),
                ),
              ),
          },
        ],
      ),
    );
  }
}
