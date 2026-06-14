import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'profile_detail_screen.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardProvider);
    final currentMetric = ref.watch(leaderboardMetricProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Leaderboard',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Text(
                            '#${resp.me!.rank}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          title: Text(
                            resp.me!.name.isNotEmpty ? resp.me!.name : 'You',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Text(
                            '${resp.me!.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: resp.rows.length,
                        itemBuilder: (context, i) {
                          final r = resp.rows[i];
                          return ListTile(
                            leading: _medal(r.rank),
                            title: Text(
                              r.name.isNotEmpty ? r.name : 'User',
                              style: TextStyle(
                                fontWeight: r.isMe
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Text(
                              '${r.value}',
                              style: const TextStyle(
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
      padding: const EdgeInsets.only(right: 8),
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

  Widget _medal(int rank) {
    switch (rank) {
      case 1:
        return const Text('🥇', style: TextStyle(fontSize: 24));
      case 2:
        return const Text('🥈', style: TextStyle(fontSize: 24));
      case 3:
        return const Text('🥉', style: TextStyle(fontSize: 24));
      default:
        return CircleAvatar(
          radius: 14,
          child: Text('#$rank', style: const TextStyle(fontSize: 12)),
        );
    }
  }
}
