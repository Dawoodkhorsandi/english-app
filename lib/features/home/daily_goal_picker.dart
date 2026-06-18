import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'providers.dart';

/// Shows a picker to choose the daily word goal and persists the choice.
/// Shared by the Home daily-goal card and the Settings screen.
Future<void> showDailyGoalPicker(BuildContext context, WidgetRef ref) {
  final current = ref.read(dailyGoalTargetProvider);
  return showDialog<void>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Daily word goal'),
      children: kDailyGoalOptions.map((g) {
        return SimpleDialogOption(
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(dailyGoalTargetProvider.notifier).set(g);
            Navigator.pop(ctx);
          },
          child: Row(
            children: [
              if (g == current)
                const Icon(Icons.check, size: 18, color: AppColors.success)
              else
                const SizedBox(width: 18),
              const SizedBox(width: AppSpacing.md),
              Text('$g words / day'),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
