import 'package:flutter/material.dart';

import '../../domain/entities/workout_session.dart';

/// One editable row inside the active-workout logger: set number, weight,
/// reps, and a completion checkbox that triggers the rest timer.
class SetLogRow extends StatelessWidget {
  const SetLogRow({
    required this.set,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onToggleCompleted,
    required this.onDelete,
    super.key,
  });

  final WorkoutSet set;
  final ValueChanged<double?> onWeightChanged;
  final ValueChanged<int?> onRepsChanged;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              set.isWarmup ? 'W' : '${set.setNumber}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: set.isWarmup ? theme.colorScheme.tertiary : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _NumberField(
              hint: 'kg',
              initialValue: set.weightKg,
              onChanged: onWeightChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumberField(
              hint: 'reps',
              initialValue: set.reps?.toDouble(),
              onChanged: (v) => onRepsChanged(v?.round()),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              set.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: set.isCompleted ? theme.colorScheme.tertiary : theme.colorScheme.outline,
            ),
            onPressed: onToggleCompleted,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.hint, required this.onChanged, this.initialValue});

  final String hint;
  final double? initialValue;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: (value) => onChanged(double.tryParse(value)),
    );
  }
}
