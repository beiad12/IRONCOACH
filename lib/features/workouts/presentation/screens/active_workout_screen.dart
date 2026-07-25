import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_template.dart';
import '../providers/active_workout_controller.dart';
import '../providers/rest_timer_controller.dart';
import '../providers/workout_providers.dart';
import '../widgets/rest_timer_sheet.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(activeWorkoutControllerProvider(sessionId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: AsyncValueWidget(
            value: sessionAsync,
            data: (session) => _ActiveWorkoutBody(session: session, onExit: () => _confirmExit(context)),
          ),
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave workout?'),
        content: const Text('Your progress is saved automatically — you can resume any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Stay')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _ActiveWorkoutBody extends HookConsumerWidget {
  const _ActiveWorkoutBody({required this.session, required this.onExit});
  final WorkoutSession session;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forces a rebuild once a second so the elapsed-time header stays live.
    final tick = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      return timer.cancel;
    }, const []);

    final templateAsync =
        session.templateId == null ? null : ref.watch(workoutTemplateByIdProvider(session.templateId!));

    Future<void> finish() async {
      final finished = await ref.read(activeWorkoutControllerProvider(session.id).notifier).finish();
      if (!context.mounted) return;
      context.pushReplacement(RoutePaths.workoutSummary.replaceFirst(':sessionId', finished.id));
    }

    return templateAsync == null
        ? _NoTemplateView(onExit: onExit, onFinish: finish)
        : templateAsync.when(
            data: (template) => template.exercises.isEmpty
                ? _NoTemplateView(onExit: onExit, onFinish: finish)
                : _SessionView(session: session, template: template, onExit: onExit, onFinish: finish),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _NoTemplateView(onExit: onExit, onFinish: finish),
          );
  }
}

class _NoTemplateView extends StatelessWidget {
  const _NoTemplateView({required this.onExit, required this.onFinish});
  final VoidCallback onExit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(elapsed: Duration.zero, onExit: onExit, onFinish: onFinish),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This session has no plan attached — start one from a template to log sets here.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionView extends HookConsumerWidget {
  const _SessionView({
    required this.session,
    required this.template,
    required this.onExit,
    required this.onFinish,
  });
  final WorkoutSession session;
  final WorkoutTemplate template;
  final VoidCallback onExit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = useState(0);
    final clampedIndex = index.value.clamp(0, template.exercises.length - 1);
    final current = template.exercises[clampedIndex];

    final setsForExercise = session.setsByExercise[current.exercise.id] ?? const [];
    final doneCount = setsForExercise.where((s) => s.isCompleted && !s.isWarmup).length;

    final weightController = useTextEditingController(
      text: (current.targetWeightKg ?? _lastWeight(setsForExercise))?.toString() ?? '',
    );
    final repsController = useTextEditingController(
      text: (current.targetRepsMin ?? _lastReps(setsForExercise))?.toString() ?? '',
    );

    // Reset the input fields whenever the current exercise changes.
    useEffect(() {
      weightController.text = (current.targetWeightKg ?? _lastWeight(setsForExercise))?.toString() ?? '';
      repsController.text = (current.targetRepsMin ?? _lastReps(setsForExercise))?.toString() ?? '';
      return null;
    }, [clampedIndex]);

    final totalSets = template.exercises.fold<int>(0, (sum, te) => sum + te.targetSets);
    final doneSets = session.sets.where((s) => s.isCompleted && !s.isWarmup).length;
    final progressPct = totalSets == 0 ? 0.0 : (doneSets / totalSets).clamp(0.0, 1.0);

    Future<void> logSet() async {
      final controller = ref.read(activeWorkoutControllerProvider(session.id).notifier);
      await controller.logSet(
        exerciseId: current.exercise.id,
        weightKg: double.tryParse(weightController.text),
        reps: int.tryParse(repsController.text),
      );
      if (!context.mounted) return;
      ref.read(restTimerControllerProvider.notifier).start(current.targetRestSeconds);
      await showRestTimerSheet(context);
    }

    return Column(
      children: [
        _TopBar(elapsed: session.elapsed, onExit: onExit, onFinish: onFinish),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 6,
              backgroundColor: AppColors.darkSurface,
              valueColor: const AlwaysStoppedAnimation(AppColors.electricBlue),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise ${clampedIndex + 1} of ${template.exercises.length}',
                  style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => context.push('${RoutePaths.exerciseLibrary}/${current.exercise.id}'),
                  child: Text(current.exercise.name, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 2),
                Text(
                  current.exercise.primaryMuscle,
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _BigNumberField(label: 'Weight (kg)', controller: weightController)),
                          const SizedBox(width: 14),
                          Expanded(child: _BigNumberField(label: 'Reps', controller: repsController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < current.targetSets; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _SetDot(filled: i < doneCount, label: '${i + 1}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Log Set & Rest',
                  variant: GradientButtonVariant.success,
                  onPressed: logSet,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: clampedIndex == 0 ? null : () => index.value = clampedIndex - 1,
                        child: const Text('← Prev'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: clampedIndex >= template.exercises.length - 1
                            ? null
                            : () => index.value = clampedIndex + 1,
                        child: const Text('Next →'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: onFinish,
                    child: const Text('Finish Workout', style: TextStyle(color: AppColors.darkTextTertiary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double? _lastWeight(List<WorkoutSet> sets) => sets.isEmpty ? null : sets.last.weightKg;
  int? _lastReps(List<WorkoutSet> sets) => sets.isEmpty ? null : sets.last.reps;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.elapsed, required this.onExit, required this.onFinish});
  final Duration elapsed;
  final VoidCallback onExit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onExit,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('✕ End'),
          ),
          Text('$mm:$ss', style: Theme.of(context).textTheme.titleMedium),
          TextButton(onPressed: onFinish, child: const Text('Finish')),
        ],
      ),
    );
  }
}

class _BigNumberField extends StatelessWidget {
  const _BigNumberField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 10, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.headlineSmall,
          decoration: const InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _SetDot extends StatelessWidget {
  const _SetDot({required this.filled, required this.label});
  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.emerald : AppColors.darkActivePill,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? AppColors.onSuccessGradient : AppColors.darkTextTertiary,
        ),
      ),
    );
  }
}
