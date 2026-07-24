import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/rest_timer_controller.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerControllerProvider);
    if (timer == null || timer.remainingSeconds <= 0) return const SizedBox.shrink();

    final minutes = timer.remainingSeconds ~/ 60;
    final seconds = timer.remainingSeconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: timer.progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.darkBorder,
                  valueColor: const AlwaysStoppedAnimation(AppColors.emberOrange),
                ),
                const Icon(Icons.timer_outlined, size: 18),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rest — ${minutes}:${seconds.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => ref.read(restTimerControllerProvider.notifier).addSeconds(15),
            child: const Text('+15s'),
          ),
          TextButton(
            onPressed: () => ref.read(restTimerControllerProvider.notifier).skip(),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}
