import 'package:flutter/material.dart';

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
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onGooglePressed,
          icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
          label: const Text('Continue with Google'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onApplePressed,
          icon: const Icon(Icons.apple_rounded, size: 22),
          label: const Text('Continue with Apple'),
        ),
      ],
    );
  }
}
