import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A standalone selectable pill — the "Goal / Duration / Equipment" chip
/// style from the design (independently wrap-laid pills, as opposed to
/// [SegmentedTabs]' single equal-width track). Same active-state visual
/// language as [SegmentedTabs] for consistency.
class AppChip extends StatelessWidget {
  const AppChip({required this.label, required this.selected, required this.onTap, super.key});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? null : AppColors.darkSurface,
            border: selected ? null : Border.all(color: AppColors.darkBorder),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      AppColors.electricBlue.withValues(alpha: 0.22),
                      AppColors.electricBlue.withValues(alpha: 0.1),
                    ],
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFFEAF4FF) : AppColors.darkTextTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
