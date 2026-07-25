import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
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
      appBar: AppBar(
        title: const Text('Train'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(RoutePaths.workoutHistory),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RoutePaths.exerciseLibrary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(workoutTemplatesProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              gradient: AppColors.heroCardGradient,
              borderColor: AppColors.electricBlue.withValues(alpha: 0.22),
              onTap: () => context.push(RoutePaths.workoutGenerator),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.electricBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate a workout', style: Theme.of(context).textTheme.titleSmall),
                        const Text(
                          'Goal, duration, equipment — ready in seconds',
                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.darkTextTertiary),
                ],
              ),
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

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.template});
  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push(RoutePaths.workoutTemplateDetail.replaceFirst(':templateId', template.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${template.exercises.length} exercises · ${template.estimatedDurationMinutes ?? "-"} min',
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              template.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: template.isFavorite ? AppColors.error : AppColors.darkTextTertiary,
            ),
            onPressed: () => ref
                .read(workoutTemplateRepositoryProvider)
                .toggleFavorite(template.id, isFavorite: !template.isFavorite)
                .then((_) => ref.invalidate(workoutTemplatesProvider)),
          ),
        ],
      ),
    );
  }
}
