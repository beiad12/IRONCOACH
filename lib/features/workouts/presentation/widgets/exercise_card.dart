import 'package:flutter/material.dart';

import '../../domain/entities/exercise.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.exercise,
    required this.onTap,
    this.onFavoriteToggle,
    this.trailing,
    super.key,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(_iconFor(exercise.category), color: theme.colorScheme.primary),
        ),
        title: Text(exercise.name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          [exercise.primaryMuscle, exercise.equipment].whereType<String>().join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: trailing ??
            (onFavoriteToggle != null
                ? IconButton(
                    icon: Icon(
                      exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: exercise.isFavorite ? theme.colorScheme.error : null,
                    ),
                    onPressed: onFavoriteToggle,
                  )
                : null),
      ),
    );
  }

  IconData _iconFor(ExerciseCategory category) => switch (category) {
        ExerciseCategory.strength => Icons.fitness_center,
        ExerciseCategory.cardio => Icons.directions_run,
        ExerciseCategory.mobility => Icons.self_improvement,
        ExerciseCategory.plyometric => Icons.bolt,
        ExerciseCategory.balance => Icons.balance,
      };
}
