import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The elevated-card surface used throughout the design: a subtle top-to-
/// bottom gradient, a hairline border, and a soft drop shadow — standard
/// `CardTheme` can't express the gradient, so every "card" surface in a
/// restyled screen should use this instead of a bare `Card`.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18,
    this.gradient,
    this.borderColor,
    this.onTap,
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.darkBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x59000000), blurRadius: 30, offset: Offset(0, 14)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}
