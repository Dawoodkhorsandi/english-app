import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// A white card showing a big colored [value] over an uppercase [label].
///
/// Used for the Home bottom stats and the Profile metric row.
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
