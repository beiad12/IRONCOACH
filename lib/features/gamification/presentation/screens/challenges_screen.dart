import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../providers/gamification_providers.dart';
import '../widgets/challenges_list.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: AsyncValueWidget(
        value: challengesAsync,
        onRetry: () => ref.invalidate(challengesProvider),
        data: (challenges) => ListView(
          padding: const EdgeInsets.all(16),
          children: [ChallengesList(challenges: challenges)],
        ),
      ),
    );
  }
}
