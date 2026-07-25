import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/ai_insight.dart';
import '../providers/notification_providers.dart';

/// Inbox of past alerts (AI insights today; workout/nutrition/recovery
/// reminders are local-only and don't leave a record to list here). Distinct
/// from [NotificationSettingsScreen], which controls whether these fire.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiInsightsProvider);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncValueWidget(
        value: insightsAsync,
        onRetry: () => ref.invalidate(aiInsightsProvider),
        data: (insights) {
          if (insights.isEmpty) {
            return const EmptyState(
                icon: Icons.notifications_none, title: 'No notifications yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: insights.length,
            itemBuilder: (context, i) => _NotificationRow(
              insight: insights[i],
              dateLabel: dateFormat.format(insights[i].createdAt),
              onTap: () async {
                if (insights[i].readAt == null) {
                  await ref
                      .read(notificationRepositoryProvider)
                      .markInsightRead(insights[i].id);
                  ref.invalidate(aiInsightsProvider);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow(
      {required this.insight, required this.dateLabel, required this.onTap});
  final AiInsight insight;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = insight.readAt == null;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Opacity(
        opacity: isUnread ? 1 : 0.55,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppColors.electricBlue, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.darkTextTertiary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(dateLabel,
                      style: const TextStyle(
                          color: AppColors.darkTextTertiary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
