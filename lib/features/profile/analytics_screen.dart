import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/analytics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/progress_bar.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: analyticsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: LoadingSkeleton(lines: 8),
        ),
        error: (e, _) => ErrorState(
          message: 'Could not load analytics',
          onRetry: () => ref.invalidate(analyticsProvider),
        ),
        data: (a) {
          final isEmpty =
              a.wordBreakdown.isEmpty &&
              a.weeklyVelocity.isEmpty &&
              a.contentDiversity.isEmpty &&
              a.quizAccuracyTrend.isEmpty;
          if (isEmpty) {
            return const EmptyState(
              icon: Icons.insights,
              title: 'No analytics yet',
              subtitle: 'Keep learning to build up your stats.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (a.wordBreakdown.isNotEmpty)
                _BarCard(
                  title: 'Word Breakdown',
                  entries: a.wordBreakdown,
                  color: AppColors.accentBlue,
                ),
              if (a.contentDiversity.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _BarCard(
                  title: 'Content Diversity',
                  entries: a.contentDiversity,
                  color: AppColors.accentPurple,
                ),
              ],
              if (a.weeklyVelocity.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _BarCard(
                  title: 'Weekly Velocity',
                  entries: a.weeklyVelocity
                      .map((w) => AnalyticsEntry(label: w.week, count: w.count))
                      .toList(),
                  color: AppColors.accentTeal,
                ),
              ],
              if (a.quizAccuracyTrend.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _QuizTrendCard(trend: a.quizAccuracyTrend),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BarCard extends StatelessWidget {
  final String title;
  final List<AnalyticsEntry> entries;
  final Color color;
  const _BarCard({
    required this.title,
    required this.entries,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxCount = entries.fold<int>(1, (m, e) => e.count > m ? e.count : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.label, style: textTheme.bodyMedium),
                        ),
                        Text(
                          '${e.count}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    ProgressBar(
                      value: e.count / maxCount,
                      height: AppSpacing.xs,
                      color: color,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizTrendCard extends StatelessWidget {
  final List<QuizTrend> trend;
  const _QuizTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Accuracy Trend',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final t in trend)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.date, style: textTheme.bodyMedium),
                        ),
                        Text(
                          '${t.correct}/${t.total} (${t.pct}%)',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    ProgressBar(
                      value: t.pct / 100,
                      height: AppSpacing.xs,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
