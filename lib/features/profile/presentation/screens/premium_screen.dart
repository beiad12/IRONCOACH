import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gradient_button.dart';

const _features = [
  'Unlimited AI Coach conversations',
  'Unlimited meal scans',
  'Advanced progress analytics',
];

/// UI-only paywall — there is no billing/IAP integration in this codebase,
/// so "Start Free Trial" is a stub. Matches the design's Premium screen
/// exactly otherwise.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandIconGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.eco, color: AppColors.onPrimaryGradient, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('IronCoach Premium', style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Unlimited AI coaching, deep analytics, meal scanning',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              for (final feature in _features)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: AppColors.emerald, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(feature, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              AppCard(
                borderColor: AppColors.electricBlue,
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Annual', style: TextStyle(color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('\$79.99/yr · Save 33%', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Text('BEST VALUE', style: TextStyle(color: AppColors.electricBlue, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly', style: TextStyle(color: AppColors.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text('\$9.99/mo', style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Start Free Trial',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium is coming soon')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
