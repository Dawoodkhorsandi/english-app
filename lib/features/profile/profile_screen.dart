import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'widgets/streak_ring.dart';
import 'widgets/stat_tiles.dart';
import 'widgets/activity_section.dart';
import 'widgets/achievement_section.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingSkeleton(lines: 8),
      ),
      error: (e, s) => ErrorState(
        message: 'Could not load stats',
        onRetry: () => ref.invalidate(statsProvider),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(statsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    StreakRing(
                      streak: stats.currentStreak,
                      longest: stats.longestStreak,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Level: ${stats.level}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Member since ${stats.memberSince}',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            StatTiles(stats: stats),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz Accuracy',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: stats.quizPct / 100,
                      minHeight: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.quizCorrect}/${stats.quizAnswered} (${stats.quizPct}%)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ActivitySection(stats: stats),
            const SizedBox(height: 16),
            AchievementSection(
              achievements: stats.achievements,
              unlocked: stats.achUnlocked,
              total: stats.achTotal,
            ),
          ],
        ),
      ),
    );
  }
}
