import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/challenge.dart';
import '../providers/gamification_providers.dart';

/// Shared challenge list — used by the standalone [ChallengesScreen] and by
/// the Community hub's Challenges tab.
class ChallengesList extends ConsumerWidget {
  const ChallengesList({required this.challenges, super.key});
  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (challenges.isEmpty) {
      return const EmptyState(
          icon: Icons.flag_outlined, title: 'No active challenges');
    }
    return Column(
      children: [
        for (final challenge in challenges)
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.name,
                        style: const TextStyle(
                            color: AppColors.darkTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('+${challenge.xpReward} XP',
                        style: const TextStyle(
                            color: AppColors.xpGold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: const TextStyle(
                      color: AppColors.darkTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: challenge.progressPercent,
                    minHeight: 6,
                    backgroundColor: AppColors.darkActivePill,
                    valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge.participantCount} participants',
                      style: const TextStyle(
                          color: AppColors.darkTextTertiary, fontSize: 12),
                    ),
                    if (!challenge.isJoined)
                      OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(gamificationRepositoryProvider)
                              .joinChallenge(challenge.id);
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
      ],
    );
  }
}
