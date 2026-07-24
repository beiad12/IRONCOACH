import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/workout_providers.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final dateFormat = DateFormat('EEE, MMM d');

    return Scaffold(
      appBar: AppBar(title: const Text('Workout history')),
      body: AsyncValueWidget(
        value: historyAsync,
        onRetry: () => ref.invalidate(workoutHistoryProvider),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(icon: Icons.history, title: 'No workouts logged yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final session = sessions[i];
              return Card(
                child: ListTile(
                  title: Text(session.name),
                  subtitle: Text(
                    '${dateFormat.format(session.startedAt)} · ${session.sets.where((s) => s.isCompleted).length} sets · ${session.totalVolumeKg.round()} kg volume',
                  ),
                  trailing: session.isActive
                      ? const Chip(label: Text('In progress'))
                      : const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    (session.isActive ? RoutePaths.activeWorkout : RoutePaths.workoutSummary)
                        .replaceFirst(':sessionId', session.id),
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
