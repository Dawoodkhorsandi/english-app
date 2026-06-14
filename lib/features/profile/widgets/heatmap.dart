import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> activityCounts;
  const ActivityHeatmap({super.key, required this.activityCounts});

  @override
  Widget build(BuildContext context) {
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

    Color cellColor(int level) {
      switch (level) {
        case 0:
          return Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]!
              : Colors.grey[200]!;
        case 1:
          return AppColors.success.withValues(alpha: 0.3);
        case 2:
          return AppColors.success.withValues(alpha: 0.5);
        case 3:
          return AppColors.success.withValues(alpha: 0.7);
        case 4:
          return AppColors.success;
        default:
          return Colors.grey[200]!;
      }
    }

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: days.map((day) {
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final count = activityCounts[key] ?? 0;
        final isToday =
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cellColor(level(count)),
            borderRadius: BorderRadius.circular(2),
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
