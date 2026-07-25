import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// A single shimmering skeleton bar, matching the design system's
/// "Skeleton Loading" token. Compose a few of these (varying [width]) to
/// mock up a loading list row/card ahead of real content.
class ShimmerBar extends StatelessWidget {
  const ShimmerBar({this.width, this.height = 14, super.key});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.darkSurface,
      highlightColor: const Color(0xFF1F2024),
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// A stack of [ShimmerBar]s sized like a text block, for list/card loading
/// placeholders.
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({this.lines = 3, super.key});

  final int lines;

  @override
  Widget build(BuildContext context) {
    const widths = [0.7, 1.0, 0.45];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => ShimmerBar(
                width: constraints.maxWidth * widths[i % widths.length]),
          ),
        ],
      ],
    );
  }
}
