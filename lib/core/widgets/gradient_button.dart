import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum GradientButtonVariant { primary, success }

/// The gradient CTA button used throughout the design ("Start Workout",
/// "Log Set & Rest", "Continue", "Sign In", ...). [PrimaryButton] remains
/// the plain solid-color button for contexts that don't call for the
/// gradient treatment; this is specifically for the two gradient variants
/// on the design system's Buttons board.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.variant = GradientButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 56,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final GradientButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == GradientButtonVariant.primary;
    final gradient = isPrimary
        ? AppColors.primaryButtonGradient
        : AppColors.successButtonGradient;
    final onColor =
        isPrimary ? AppColors.onPrimaryGradient : AppColors.onSuccessGradient;
    final shadowColor = isPrimary
        ? AppColors.electricBlue.withOpacity(0.3)
        : AppColors.emerald.withOpacity(0.25);
    final disabled = onPressed == null || isLoading;

    return Opacity(
      opacity: disabled && isLoading ? 0.85 : (disabled ? 0.4 : 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: shadowColor,
                    blurRadius: 28,
                    offset: const Offset(0, 12))
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: onColor),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: onColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                              color: onColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
