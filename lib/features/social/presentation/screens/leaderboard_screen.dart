import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../providers/social_providers.dart';
import '../widgets/leaderboard_list.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: AsyncValueWidget(
        value: leaderboardAsync,
        onRetry: () => ref.invalidate(leaderboardProvider),
        data: (entries) => ListView(
          padding: const EdgeInsets.all(16),
          children: [LeaderboardList(entries: entries)],
        ),
      ),
    );
  }
}
