import 'package:flutter/material.dart';
import '../../../core/models/achievement.dart';

class AchievementSection extends StatelessWidget {
  final List<Achievement> achievements;
  final int unlocked;
  final int total;
  const AchievementSection({super.key, required this.achievements, required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Achievement>>{};
    for (final a in achievements) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('\u{1F3C6} Achievements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('$unlocked / $total', style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
            children: entry.value.map((a) => ListTile(
              leading: Text(a.icon, style: const TextStyle(fontSize: 24)),
              title: Text(a.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.description, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: a.target > 0 ? a.progress / a.target : 0,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
              trailing: a.unlocked ? const Icon(Icons.check_circle, color: Colors.green) : null,
            )).toList(),
          ),
        )),
      ],
    );
  }
}
