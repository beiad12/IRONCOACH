import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../social/domain/entities/post.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../providers/workout_providers.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(workoutSessionByIdProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Workout complete')),
      body: AsyncValueWidget(
        value: sessionAsync,
        data: (session) {
          final completedSets = session.sets.where((s) => s.isCompleted && !s.isWarmup).toList();
          final duration = session.elapsed;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Icon(Icons.emoji_events, size: 64, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Center(child: Text(session.name, style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Duration', value: '${duration.inMinutes} min'),
                  _Stat(label: 'Sets', value: '${completedSets.length}'),
                  _Stat(label: 'Volume', value: '${session.totalVolumeKg.round()} kg'),
                ],
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share with friends'),
                onPressed: () async {
                  final result = await ref.read(socialRepositoryProvider).createPost(
                        postType: PostType.workout,
                        caption: '${session.name} · ${session.totalVolumeKg.round()} kg volume',
                        workoutSessionId: session.id,
                      );
                  if (!context.mounted) return;
                  result.match(
                    (failure) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
                    (_) => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Shared to your feed'))),
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(RoutePaths.workouts),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
