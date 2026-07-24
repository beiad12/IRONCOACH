import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gamification/presentation/providers/gamification_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final levelAsync = ref.watch(myLevelProvider);

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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile.displayName ?? profile.username,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Center(
                child: Text('@${profile.username}', style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              Center(
                child: levelAsync.when(
                  data: (level) => Chip(label: Text('Level ${level?.level ?? 1}')),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Achievements'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.achievements),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Challenges'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.challenges),
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Friends'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.friends),
              ),
              ListTile(
                leading: const Icon(Icons.leaderboard_outlined),
                title: const Text('Leaderboard'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.leaderboard),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.read(signOutProvider).call(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
