import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'widgets/streak_ring.dart';
import 'widgets/stat_tiles.dart';
import 'widgets/activity_section.dart';
import 'widgets/achievement_section.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';
import '../../core/theme/app_spacing.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: LoadingSkeleton(lines: 8),
        ),
        error: (e, s) => ErrorState(
          message: 'Could not load stats',
          onRetry: () => ref.invalidate(statsProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(statsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      StreakRing(
                        streak: stats.currentStreak,
                        longest: stats.longestStreak,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Level: ${stats.level}',
                        style: textTheme.titleMedium,
                      ),
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
              StatTiles(stats: stats),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Accuracy',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
                        '${stats.quizCorrect}/${stats.quizAnswered} (${stats.quizPct}%)',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ActivitySection(stats: stats),
              const SizedBox(height: AppSpacing.lg),
              AchievementSection(
                achievements: stats.achievements,
                unlocked: stats.achUnlocked,
                total: stats.achTotal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
