import 'package:flutter/material.dart';
import '../../../core/models/stats.dart';
import '../../../core/theme/app_spacing.dart';
import 'heatmap.dart';

class ActivitySection extends StatelessWidget {
  final Stats stats;
  const ActivitySection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${stats.activeDays}', 'Active days', textTheme),
                _statItem(
                  '${stats.activityDays.length}',
                  'This week',
                  textTheme,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ActivityHeatmap(activityCounts: stats.activityCounts),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
