import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> activityCounts;
  const ActivityHeatmap({super.key, required this.activityCounts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 111; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    int level(int count) {
      if (count == 0) return 0;
      if (count < 3) return 1;
      if (count < 6) return 2;
      if (count < 10) return 3;
      return 4;
    }

    Color cellColor(int lvl) {
      switch (lvl) {
        case 1:
          return isDark ? AppColors.heatmapLowDark : AppColors.heatmapLow;
        case 2:
          return isDark ? AppColors.heatmapMedDark : AppColors.heatmapMed;
        case 3:
        case 4:
          return isDark ? AppColors.heatmapHighDark : AppColors.heatmapHigh;
        default:
          return isDark ? AppColors.heatmapEmptyDark : AppColors.heatmapEmpty;
      }
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: days.map((day) {
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final count = activityCounts[key] ?? 0;
        final isToday =
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        return Container(
          width: AppSpacing.md,
          height: AppSpacing.md,
          decoration: BoxDecoration(
            color: cellColor(level(count)),
            borderRadius: AppRadius.borderXs,
            border: isToday
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
