import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'profile_detail_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

/// Full leaderboard screen, pushed from Profile.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final boardAsync = ref.watch(leaderboardProvider);
    final currentMetric = ref.watch(leaderboardMetricProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'words', label: Text('All-time')),
                ButtonSegment(value: 'weekly', label: Text('Week')),
                ButtonSegment(value: 'today', label: Text('Today')),
                ButtonSegment(value: 'mastered', label: Text('Mastered')),
              ],
              selected: {currentMetric},
              onSelectionChanged: (selection) {
                HapticFeedback.selectionClick();
                ref.read(leaderboardMetricProvider.notifier).state =
                    selection.first;
                ref.invalidate(leaderboardProvider);
              },
            ),
          ),
          Expanded(
            child: boardAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: LoadingSkeleton(lines: 10),
              ),
              error: (e, _) => ErrorState(
                message: 'Could not load leaderboard',
                onRetry: () => ref.invalidate(leaderboardProvider),
              ),
              data: (resp) {
                if (resp.rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.leaderboard,
                    title: 'No users yet.',
                    subtitle: 'Start learning to get on the board!',
                  );
                }
                return Column(
                  children: [
                    if (resp.me != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pagePadding,
                        ),
                        child: Card(
                          color: colorScheme.primaryContainer,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Text(
                                '#${resp.me!.rank}',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
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
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pagePadding,
                        ),
                        itemCount: resp.rows.length,
                        itemBuilder: (context, i) {
                          final r = resp.rows[i];
                          return ListTile(
                            leading: _rankBadge(r.rank, colorScheme, textTheme),
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

  Widget _rankBadge(int rank, ColorScheme cs, TextTheme tt) {
    Color? bg;
    Color? fg;
    switch (rank) {
      case 1:
        bg = const Color(0xFFFFD700);
        fg = Colors.black;
        break;
      case 2:
        bg = const Color(0xFFC0C0C0);
        fg = Colors.black;
        break;
      case 3:
        bg = const Color(0xFFCD7F32);
        fg = Colors.white;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: bg,
      child: Text(
        '$rank',
        style: tt.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
