import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/auth_providers.dart';

/// Three-step goal/level/units capture shown once after sign-up, so the
/// AI coaches and workout generator have enough context to be useful
/// immediately instead of asking the user to fill in a blank profile.
class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final selectedGoal = useState<PrimaryGoal?>(null);
    final selectedLevel = useState(FitnessLevel.beginner);
    final selectedUnits = useState(MeasurementUnits.metric);
    final isSaving = useState(false);

    Future<void> finish() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      isSaving.value = true;

      final profileResult = await ref.read(profileRepositoryProvider).getProfile(user.id);
      await profileResult.match(
        (_) async {},
        (profile) => ref.read(profileRepositoryProvider).updateProfile(
              profile.copyWith(
                primaryGoal: selectedGoal.value,
                fitnessLevel: selectedLevel.value,
                units: selectedUnits.value,
              ),
            ),
      );
      await ref.read(authRepositoryProvider).markOnboardingComplete();
      isSaving.value = false;
      if (context.mounted) context.go(RoutePaths.home);
    }

    void next() {
      if (currentPage.value == 2) {
        finish();
      } else {
        pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= currentPage.value
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => currentPage.value = i,
                children: [
                  _GoalStep(selected: selectedGoal.value, onSelect: (g) => selectedGoal.value = g),
                  _LevelStep(selected: selectedLevel.value, onSelect: (l) => selectedLevel.value = l),
                  _UnitsStep(selected: selectedUnits.value, onSelect: (u) => selectedUnits.value = u),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: currentPage.value == 2 ? "Let's go" : 'Continue',
                isLoading: isSaving.value,
                onPressed: currentPage.value == 0 && selectedGoal.value == null ? null : next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.selected, required this.onSelect});
  final PrimaryGoal? selected;
  final ValueChanged<PrimaryGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "What's your main goal?",
      child: Column(
        children: PrimaryGoal.values
            .map(
              (goal) => RadioListTile<PrimaryGoal>(
                title: Text(goal.label),
                value: goal,
                groupValue: selected,
                onChanged: (v) => onSelect(v!),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.selected, required this.onSelect});
  final FitnessLevel selected;
  final ValueChanged<FitnessLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "What's your training experience?",
      child: Column(
        children: FitnessLevel.values
            .map(
              (level) => RadioListTile<FitnessLevel>(
                title: Text(level.name[0].toUpperCase() + level.name.substring(1)),
                value: level,
                groupValue: selected,
                onChanged: (v) => onSelect(v!),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _UnitsStep extends StatelessWidget {
  const _UnitsStep({required this.selected, required this.onSelect});
  final MeasurementUnits selected;
  final ValueChanged<MeasurementUnits> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Which units do you prefer?',
      child: Column(
        children: MeasurementUnits.values
            .map(
              (unit) => RadioListTile<MeasurementUnits>(
                title: Text(unit == MeasurementUnits.metric ? 'Metric (kg, cm)' : 'Imperial (lb, in)'),
                value: unit,
                groupValue: selected,
                onChanged: (v) => onSelect(v!),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
