import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/onboarding_providers.dart';

class _Slide {
  const _Slide({required this.icon, required this.iconColor, required this.title, required this.body});
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    icon: Icons.auto_awesome,
    iconColor: AppColors.electricBlue,
    title: 'Coaching that adapts to you',
    body: 'IronCoach reads your recovery, effort and history to rebuild your plan every single '
        'day — no generic templates.',
  ),
  _Slide(
    icon: Icons.fitness_center,
    iconColor: AppColors.emerald,
    title: 'Train anywhere, anytime',
    body: 'From full gyms to bodyweight-only sessions — every workout is built around the '
        'equipment you actually have.',
  ),
  _Slide(
    icon: Icons.bar_chart_rounded,
    iconColor: AppColors.electricBlue,
    title: 'See real progress',
    body: 'Track weight, measurements and performance trends with analytics that actually '
        'explain what changed.',
  ),
];

/// Pre-auth marketing carousel — matches the design's `onboarding` stage
/// exactly: three slides, a Skip shortcut, and no data collection (goal/
/// experience-level/units now live in Edit Profile instead of gating
/// signup).
class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final index = useState(0);

    void finish() {
      ref.read(hasSeenOnboardingProvider.notifier).markSeen();
      context.go(RoutePaths.auth);
    }

    void next() {
      if (index.value < _slides.length - 1) {
        pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
      } else {
        finish();
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: finish,
                  child: const Text('Skip', style: TextStyle(color: AppColors.darkTextSecondary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => index.value = i,
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    GestureDetector(
                      onTap: () => pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == index.value ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == index.value ? AppColors.electricBlue : AppColors.darkText(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GradientButton(label: 'Continue', onPressed: next),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1C22), Color(0xFF111216)],
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.darkBorder),
            boxShadow: [
              BoxShadow(color: AppColors.electricBlue.withValues(alpha: 0.14), blurRadius: 70),
            ],
          ),
          child: Icon(slide.icon, size: 70, color: slide.iconColor),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 130,
          child: Column(
            children: [
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
