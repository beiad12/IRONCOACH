import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../../../workouts/presentation/providers/workout_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final streakAsync = ref.watch(myStreakProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final workoutCountAsync = ref.watch(completedWorkoutCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: profileAsync,
        onRetry: () => ref.invalidate(myProfileProvider),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          final subtitle = [
            profile.fitnessLevel.name[0].toUpperCase() + profile.fitnessLevel.name.substring(1),
            if (profile.primaryGoal != null) profile.primaryGoal!.label,
          ].join(' · ');

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandIconGradient,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: profile.avatarUrl != null
                        ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName ?? profile.username,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(subtitle, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${workoutCountAsync.valueOrNull ?? "—"}',
                      label: 'Workouts',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${streakAsync.valueOrNull?.currentStreak ?? 0}',
                      label: 'Streak',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: '${achievementsAsync.valueOrNull?.where((a) => a.isUnlocked).length ?? "—"}',
                      label: 'Badges',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                gradient: AppColors.premiumCardGradient,
                borderColor: AppColors.electricBlue.withOpacity(0.25),
                onTap: () => context.push(RoutePaths.premium),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Go Premium', style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const Icon(Icons.arrow_forward, color: AppColors.electricBlue),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _MenuRow(
                label: 'Edit profile',
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              _MenuRow(
                label: 'Settings',
                onTap: () => context.push(RoutePaths.settings),
              ),
              _MenuRow(
                label: 'Notifications',
                onTap: () => context.push(RoutePaths.notifications),
              ),
              _MenuRow(
                label: 'Progress Analytics',
                onTap: () => context.go(RoutePaths.progress),
              ),
              _MenuRow(
                label: 'Community',
                onTap: () => context.push(RoutePaths.community),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.read(signOutProvider).call(),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Sign out', style: TextStyle(color: AppColors.error)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 10, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14)),
            const Icon(Icons.chevron_right, color: AppColors.darkTextTertiary),
          ],
        ),
      ),
    );
  }
}
