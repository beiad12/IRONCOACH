import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/rest_timer_controller.dart';

/// Opens the rest-timer bottom sheet (blurred backdrop, circular countdown,
/// +15s / Skip) and automatically dismisses itself once the countdown
/// reaches zero — matching the design's rest overlay exactly.
Future<void> showRestTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.65),
    builder: (context) => const _RestTimerSheetContent(),
  );
}

class _RestTimerSheetContent extends ConsumerWidget {
  const _RestTimerSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerControllerProvider);

    ref.listen(restTimerControllerProvider, (previous, next) {
      if (next == null || (!next.isRunning && next.remainingSeconds <= 0)) {
        Navigator.of(context).maybePop();
      }
    });

    if (timer == null) return const SizedBox.shrink();

    final minutes = timer.remainingSeconds ~/ 60;
    final seconds = timer.remainingSeconds % 60;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          decoration: BoxDecoration(
            color: const Color(0xE0181A1D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkText(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'REST',
                style: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: timer.progress,
                        strokeWidth: 6,
                        backgroundColor: AppColors.darkActivePill,
                        valueColor: const AlwaysStoppedAnimation(AppColors.electricBlue),
                      ),
                    ),
                    Text(
                      '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(restTimerControllerProvider.notifier).addSeconds(15),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: const Text('+15 sec'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => ref.read(restTimerControllerProvider.notifier).skip(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: AppColors.onPrimaryGradient,
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
