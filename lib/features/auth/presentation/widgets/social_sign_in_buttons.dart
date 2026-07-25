import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.darkBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR',
                style: TextStyle(color: AppColors.darkText(0.3), fontSize: 11, letterSpacing: 0.5),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.darkBorder)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onApplePressed,
                icon: const Icon(Icons.apple_rounded, size: 20),
                label: const Text('Apple'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onGooglePressed,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
