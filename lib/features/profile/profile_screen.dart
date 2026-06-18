import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'analytics_screen.dart';
import 'widgets/activity_section.dart';
import 'widgets/achievement_section.dart';
import '../ranks/leaderboard_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/icon_chip.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/stat_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final statsAsync = ref.watch(statsProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(statsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.md,
          ),
          children: [
            // --- Header ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            statsAsync.when(
              loading: () => const LoadingSkeleton(lines: 8),
              error: (e, _) => ErrorState(
                message: 'Could not load stats',
                onRetry: () => ref.invalidate(statsProvider),
              ),
              data: (stats) => _ProfileBody(stats: stats),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final dynamic stats;
  const _ProfileBody({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final name = (auth.name != null && auth.name!.isNotEmpty)
        ? auth.name!
        : 'Learner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Identity row ---
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: AppRadius.borderLg,
              ),
              child: Text(
                name[0].toUpperCase(),
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${stats.level} · Member since ${stats.memberSince}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.deepOrange,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.currentStreak}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'DAY STREAK',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // --- Stat cards ---
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${stats.words}',
                label: 'Words',
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatCard(
                value: '${stats.mastered}',
                label: 'Mastered',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatCard(
                value: '${stats.currentStreak}',
                label: 'Streak',
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatCard(
                value: '${stats.quizPct}%',
                label: 'Quiz',
                color: AppColors.accentPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // --- Quiz accuracy ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                ProgressRing(
                  progress: stats.quizPct / 100.0,
                  size: 64,
                  strokeWidth: 6,
                  color: AppColors.accentPurple,
                  child: Text(
                    '${stats.quizPct}%',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Accuracy',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${stats.quizCorrect} correct out of ${stats.quizAnswered}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // --- Activity ---
        ActivitySection(stats: stats),
        const SizedBox(height: AppSpacing.lg),

        // --- Nav rows ---
        _NavRow(
          icon: Icons.bar_chart,
          color: AppColors.accentBlue,
          background: AppColors.accentBlueBg,
          label: 'Analytics',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
        ),
        const SizedBox(height: AppSpacing.sm),
        _NavRow(
          icon: Icons.emoji_events_outlined,
          color: AppColors.accentOrange,
          background: AppColors.accentOrangeBg,
          label: 'Leaderboard',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
        ),
        const SizedBox(height: AppSpacing.lg),

        // --- Achievements ---
        AchievementSection(
          achievements: stats.achievements,
          unlocked: stats.achUnlocked,
          total: stats.achTotal,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String label;
  final VoidCallback onTap;
  const _NavRow({
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconChip(icon: icon, color: color, background: background),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
