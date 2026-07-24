import 'package:flutter/material.dart';

class MacroBar extends StatelessWidget {
  const MacroBar({
    required this.label,
    required this.consumedG,
    required this.goalG,
    required this.color,
    super.key,
  });

  final String label;
  final double consumedG;
  final int goalG;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = goalG == 0 ? 0.0 : (consumedG / goalG).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text('${consumedG.round()}g / ${goalG}g', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
