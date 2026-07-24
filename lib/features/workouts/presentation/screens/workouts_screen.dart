import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/workout_template.dart';
import '../providers/workout_providers.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(workoutTemplatesProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(workoutTemplatesProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.auto_awesome,
                    label: 'Generate workout',
                    onTap: () => context.push(RoutePaths.workoutGenerator),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.search,
                    label: 'Exercise library',
                    onTap: () => context.push(RoutePaths.exerciseLibrary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.history,
              label: 'Workout history',
              onTap: () => context.push(RoutePaths.workoutHistory),
              fullWidth: true,
            ),
            const SizedBox(height: 24),
            Text('Your templates', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: templatesAsync,
              onRetry: () => ref.invalidate(workoutTemplatesProvider),
              data: (templates) {
                if (templates.isEmpty) {
                  return const EmptyState(
                    icon: Icons.fitness_center_outlined,
                    title: 'No templates yet',
                    message: 'Generate a workout or ask your AI coach to build one.',
                  );
                }
                return Column(
                  children: templates.map((t) => _TemplateTile(template: t)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap, this.fullWidth = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Flexible(child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.template});
  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(template.name),
        subtitle: Text('${template.exercises.length} exercises · ${template.estimatedDurationMinutes ?? "-"} min'),
        trailing: IconButton(
          icon: Icon(template.isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: () => ref
              .read(workoutTemplateRepositoryProvider)
              .toggleFavorite(template.id, isFavorite: !template.isFavorite)
              .then((_) => ref.invalidate(workoutTemplatesProvider)),
        ),
        onTap: () => context.push(RoutePaths.workoutTemplateDetail.replaceFirst(':templateId', template.id)),
      ),
    );
  }
}
