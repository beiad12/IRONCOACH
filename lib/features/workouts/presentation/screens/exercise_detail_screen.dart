import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../providers/workout_providers.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({required this.exerciseId, super.key});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: AsyncValueWidget(
        value: exerciseAsync,
        onRetry: () => ref.invalidate(exerciseByIdProvider(exerciseId)),
        data: (exercise) {
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(child: Text(exercise.name, style: theme.textTheme.headlineSmall)),
                  IconButton(
                    icon: Icon(
                      exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: exercise.isFavorite ? theme.colorScheme.error : null,
                    ),
                    onPressed: () => ref
                        .read(exerciseRepositoryProvider)
                        .toggleFavorite(exercise.id, isFavorite: !exercise.isFavorite)
                        .then((_) => ref.invalidate(exerciseByIdProvider(exerciseId))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(exercise.category.name)),
                  Chip(label: Text(exercise.primaryMuscle)),
                  if (exercise.equipment != null) Chip(label: Text(exercise.equipment!)),
                  Chip(label: Text(exercise.difficulty.name)),
                ],
              ),
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Secondary muscles', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(exercise.secondaryMuscles.join(', ')),
              ],
              if (exercise.instructions != null) ...[
                const SizedBox(height: 20),
                Text('Instructions', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(exercise.instructions!, style: theme.textTheme.bodyMedium),
              ],
            ],
          );
        },
      ),
    );
  }
}
