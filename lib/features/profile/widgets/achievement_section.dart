import 'package:flutter/material.dart';
import '../../../core/models/achievement.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AchievementSection extends StatelessWidget {
  final List<Achievement> achievements;
  final int unlocked;
  final int total;
  const AchievementSection({
    super.key,
    required this.achievements,
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final grouped = <String, List<Achievement>>{};
    for (final a in achievements) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '\u{1F3C6} Achievements',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$unlocked / $total',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...grouped.entries.map(
          (entry) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
            child: ExpansionTile(
              title: Text(
                entry.key,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: entry.value
                  .map(
                    (a) => ListTile(
                      leading: Text(a.icon, style: textTheme.headlineSmall),
                      title: Text(a.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          LinearProgressIndicator(
                            value: a.target > 0 ? a.progress / a.target : 0,
                            backgroundColor: colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ],
                      ),
                      trailing: a.unlocked
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            )
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
