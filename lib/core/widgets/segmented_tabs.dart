import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SegmentedTabOption<T> {
  const SegmentedTabOption({required this.value, required this.label});
  final T value;
  final String label;
}

/// The pill segmented control used throughout the design for in-screen
/// sub-navigation (Analytics Weight/Measurements, Nutrition Tracker/
/// Calories/Scanner, Community's four sections, ...): a dark `#111214`
/// track holding equal-width pills, the active one lit with a soft blue
/// gradient.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.scrollable = false,
    super.key,
  });

  final List<SegmentedTabOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  /// When true, pills size to their label and the row scrolls horizontally
  /// (used for longer option sets like Community's four tabs) instead of
  /// splitting the track evenly.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final track = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkTrack,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x73000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: scrollable
          ? Row(mainAxisSize: MainAxisSize.min, children: _pills())
          : Row(children: _pills().map((p) => Expanded(child: p)).toList()),
    );

    if (!scrollable) return track;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal, child: track);
  }

  List<Widget> _pills() {
    return [
      for (final option in options)
        _Pill(
          label: option.label,
          isActive: option.value == selected,
          onTap: () => onChanged(option.value),
        ),
    ];
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.electricBlue.withOpacity(0.22),
                        AppColors.electricBlue.withOpacity(0.1),
                      ],
                    )
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFFEAF4FF)
                    : AppColors.darkTextTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
