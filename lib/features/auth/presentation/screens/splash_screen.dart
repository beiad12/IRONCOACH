import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Shown only while the initial auth state is resolving; [GoRouter]'s
/// redirect takes over as soon as `authStateStreamProvider` settles.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.emberOrange, size: 64)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.12, 1.12),
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 16),
            const Text(
              'IronCoach',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
