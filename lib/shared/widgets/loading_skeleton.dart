import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class LoadingSkeleton extends StatelessWidget {
  final int lines;
  const LoadingSkeleton({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerLow,
      child: Column(
        children: List.generate(
          lines,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              height: AppSpacing.skeletonLineHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.borderXs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
