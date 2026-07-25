import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/theme/app_colors.dart';

class CalorieRing extends StatelessWidget {
  const CalorieRing({required this.consumed, required this.goal, super.key});
  final double consumed;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final percent = goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
    final remaining = (goal - consumed).round();

    return CircularPercentIndicator(
      radius: 76,
      lineWidth: 14,
      percent: percent,
      backgroundColor: AppColors.darkBorder,
      progressColor: AppColors.electricBlue,
      circularStrokeCap: CircularStrokeCap.round,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${consumed.round()}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            remaining >= 0 ? '$remaining left' : '${-remaining} over',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
