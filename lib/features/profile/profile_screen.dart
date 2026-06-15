import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'widgets/activity_section.dart';
import 'widgets/achievement_section.dart';
import '../ranks/providers.dart';
import '../ranks/leaderboard_screen.dart';
import '../ranks/profile_detail_screen.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: LoadingSkeleton(lines: 8),
      ),
      error: (e, _) => ErrorState(
        message: 'Could not load stats',
        onRetry: () => ref.invalidate(statsProvider),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsProvider);
          ref.invalidate(leaderboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.md,
          ),
          children: [
            // --- Stat summary row ---
            Row(
              children: [
                _MetricCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.deepOrange,
                  value: '${stats.currentStreak}',
                  label: 'Streak',
                ),
                const SizedBox(width: AppSpacing.sm),
                _MetricCard(
                  icon: Icons.auto_stories,
                  iconColor: colorScheme.primary,
                  value: '${stats.words}',
                  label: 'Words',
                ),
                const SizedBox(width: AppSpacing.sm),
                _MetricCard(
                  icon: Icons.check_circle,
                  iconColor: const Color(0xFF22C55E),
                  value: '${stats.mastered}',
                  label: 'Mastered',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    Text(
                      'Level: ${stats.level}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Member since ${stats.memberSince}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Quiz accuracy ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Accuracy',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: stats.quizPct / 100,
                      minHeight: AppSpacing.sm,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${stats.quizCorrect}/${stats.quizAnswered} correct (${stats.quizPct}%)',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Activity heatmap ---
            ActivitySection(stats: stats),
            const SizedBox(height: AppSpacing.lg),

            // --- Leaderboard preview ---
            _SectionHeader(
              title: 'Leaderboard',
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LeaderboardScreen(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _LeaderboardPreview(),
            const SizedBox(height: AppSpacing.lg),

            // --- Achievements ---
            AchievementSection(
              achievements: stats.achievements,
              unlocked: stats.achUnlocked,
              total: stats.achTotal,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View all'),
          ),
      ],
    );
  }
}

class _LeaderboardPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final boardAsync = ref.watch(leaderboardProvider);

    return boardAsync.when(
      loading: () => const LoadingSkeleton(lines: 3),
      error: (_, __) => const SizedBox.shrink(),
      data: (resp) {
        if (resp.rows.isEmpty) return const SizedBox.shrink();
        final preview = resp.rows.take(3).toList();
        return Card(
          child: Column(
            children: [
              for (final r in preview)
                ListTile(
                  dense: true,
                  leading: _rankBadge(r.rank, colorScheme, textTheme),
                  title: Text(
                    r.name.isNotEmpty ? r.name : 'User',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          r.isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '${r.value}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(userId: r.id),
                    ),
                  ),
                ),
              if (resp.me != null && !preview.any((r) => r.isMe))
                ListTile(
                  dense: true,
                  leading: _rankBadge(resp.me!.rank, colorScheme, textTheme),
                  title: Text(
                    'You',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    '${resp.me!.value}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _rankBadge(int rank, ColorScheme cs, TextTheme tt) {
    Color bg;
    Color fg;
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
      radius: 14,
      backgroundColor: bg,
      child: Text(
        '$rank',
        style: tt.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
