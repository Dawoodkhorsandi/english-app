import 'package:flutter/material.dart';
import '../../../core/models/stats.dart';
import 'heatmap.dart';

class ActivitySection extends StatelessWidget {
  final Stats stats;
  const ActivitySection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${stats.activeDays}', 'Active days'),
                _statItem('${stats.activityDays.length}', 'This week'),
              ],
            ),
            const SizedBox(height: 16),
            ActivityHeatmap(activityCounts: stats.activityCounts),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
