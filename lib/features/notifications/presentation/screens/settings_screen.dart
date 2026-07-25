import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AsyncValueWidget(
        value: profileAsync,
        data: (profile) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.editProfile),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notification preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.notificationSettings),
              ),
              if (profile != null) ...[
                ListTile(
                  leading: const Icon(Icons.straighten_outlined),
                  title: const Text('Units'),
                  trailing: Text(
                    profile.units == MeasurementUnits.metric ? 'Metric' : 'Imperial',
                    style: const TextStyle(color: AppColors.darkTextSecondary),
                  ),
                  onTap: () async {
                    final next = profile.units == MeasurementUnits.metric
                        ? MeasurementUnits.imperial
                        : MeasurementUnits.metric;
                    await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(units: next));
                    ref.invalidate(myProfileProvider);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text('Public profile'),
                  subtitle: const Text('Visible on leaderboards and to friends'),
                  value: profile.isPublic,
                  onChanged: (v) async {
                    await ref
                        .read(profileRepositoryProvider)
                        .updateProfile(profile.copyWith(isPublic: v));
                    ref.invalidate(myProfileProvider);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Help & Support'),
                    content: const Text('Reach us at support@ironcoach.app'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppColors.darkBorder),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                onTap: () => ref.read(signOutProvider).call(),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('IronCoach v0.1.0', style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
