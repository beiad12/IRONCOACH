import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/achievement.dart';

/// Pure-presentational 2-column achievement badge grid — matches the
/// design's Community "Achievements" tab exactly. Used both by the
/// standalone [AchievementsScreen] (with the level/XP header above it) and
/// by the Community hub's Achievements tab.
class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({required this.achievements, super.key});
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, i) => _AchievementBadge(achievement: achievements[i]),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(achievement.tier);
    return Opacity(
      opacity: achievement.isUnlocked ? 1 : 0.4,
      child: AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.emoji_events, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _tierColor(AchievementTier tier) => switch (tier) {
        AchievementTier.bronze => const Color(0xFFCD7F32),
        AchievementTier.silver => const Color(0xFFC0C0C0),
        AchievementTier.gold => AppColors.xpGold,
        AchievementTier.platinum => const Color(0xFFB9F2FF),
      };
}
