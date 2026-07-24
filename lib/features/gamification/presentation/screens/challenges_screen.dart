import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/gamification_providers.dart';

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
        data: (challenges) {
          if (challenges.isEmpty) {
            return const EmptyState(icon: Icons.flag_outlined, title: 'No active challenges');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, i) {
              final challenge = challenges[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(challenge.name, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Text('+${challenge.xpReward} XP'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(challenge.description, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: challenge.progressPercent, minHeight: 8),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${challenge.participantCount} participants'),
                          if (!challenge.isJoined)
                            FilledButton.tonal(
                              onPressed: () async {
                                await ref.read(gamificationRepositoryProvider).joinChallenge(challenge.id);
                                ref.invalidate(challengesProvider);
                              },
                              child: const Text('Join'),
                            )
                          else
                            const Chip(label: Text('Joined')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
