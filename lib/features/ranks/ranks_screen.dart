import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'profile_detail_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final boardAsync = ref.watch(leaderboardProvider);
    final currentMetric = ref.watch(leaderboardMetricProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Leaderboard',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _metricChip(ref, 'words', 'All-time', currentMetric),
                _metricChip(ref, 'weekly', 'This week', currentMetric),
                _metricChip(ref, 'today', 'Today', currentMetric),
                _metricChip(ref, 'mastered', 'Mastered', currentMetric),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: boardAsync.when(
              loading: () => const LoadingSkeleton(lines: 10),
              error: (e, s) => ErrorState(
                message: 'Could not load leaderboard',
                onRetry: () => ref.invalidate(leaderboardProvider),
              ),
              data: (resp) {
                if (resp.rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.leaderboard,
                    title: 'No users on the leaderboard yet.',
                    subtitle: 'Start learning to get on the board!',
                  );
                }
                return Column(
                  children: [
                    if (resp.me != null)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          leading: Text(
                            '#${resp.me!.rank}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: Text(
                            resp.me!.name.isNotEmpty ? resp.me!.name : 'You',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Text(
                            '${resp.me!.value}',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: resp.rows.length,
                        itemBuilder: (context, i) {
                          final r = resp.rows[i];
                          return ListTile(
                            leading: _medal(r.rank, textTheme),
                            title: Text(
                              r.name.isNotEmpty ? r.name : 'User',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: r.isMe
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Text(
                              '${r.value}',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileDetailScreen(userId: r.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(
    WidgetRef ref,
    String metric,
    String label,
    String current,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.chipGap),
      child: FilterChip(
        label: Text(label),
        selected: current == metric,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          ref.read(leaderboardMetricProvider.notifier).state = metric;
          ref.invalidate(leaderboardProvider);
        },
      ),
    );
  }

  Widget _medal(int rank, TextTheme textTheme) {
    switch (rank) {
      case 1:
        return Text('🥇', style: textTheme.headlineSmall);
      case 2:
        return Text('🥈', style: textTheme.headlineSmall);
      case 3:
        return Text('🥉', style: textTheme.headlineSmall);
      default:
        return CircleAvatar(
          radius: 14,
          child: Text('#$rank', style: textTheme.labelSmall),
        );
    }
  }
}
