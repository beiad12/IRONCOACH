import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../providers/workout_providers.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({required this.exerciseId, super.key});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      body: AsyncValueWidget(
        value: exerciseAsync,
        onRetry: () => ref.invalidate(exerciseByIdProvider(exerciseId)),
        data: (exercise) {
          final theme = Theme.of(context);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  Container(
                    height: 220,
                    decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_outline, size: 48, color: AppColors.darkTextTertiary),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: SafeArea(
                      bottom: false,
                      child: BackButton(
                        color: Colors.white,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.4)),
                          shape: const WidgetStatePropertyAll(CircleBorder()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 8),
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
                      const Text(
                        'FORM CUES',
                        style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.instructions!,
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
