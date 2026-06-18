import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'daily_goal_picker.dart';
import '../profile/providers.dart';
import '../study/providers.dart';
import '../review/providers.dart' as review_providers;
import '../review/widgets/swipe_card.dart';
import '../quiz/quiz_screen.dart';
import '../study/practice_screen.dart';
import '../study/deck_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/navigation/app_router.dart';
import '../../shared/widgets/gradient_card.dart';
import '../../shared/widgets/icon_chip.dart';
import '../../shared/widgets/pill_badge.dart';
import '../../shared/widgets/progress_bar.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final statsAsync = ref.watch(statsProvider);
    final decksAsync = ref.watch(decksProvider);
    final reviewCountAsync = ref.watch(reviewCountProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsProvider);
          ref.invalidate(decksProvider);
          ref.invalidate(reviewCountProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.md,
          ),
          children: [
            // --- Header: greeting + streak + settings ---
            const _Header(),
            const SizedBox(height: AppSpacing.xl),

            // --- Review hero (gradient) ---
            reviewCountAsync.when(
              loading: () => const LoadingSkeleton(lines: 3),
              error: (e, _) => ErrorState(
                message: 'Could not load review count',
                onRetry: () => ref.invalidate(reviewCountProvider),
              ),
              data: (count) => _ReviewHero(count: count),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Daily goal ---
            const _DailyGoalCard(),
            const SizedBox(height: AppSpacing.xl),

            // --- Quick Practice ---
            Text(
              'Quick Practice',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.bolt,
                    color: AppColors.accentPurple,
                    background: AppColors.accentPurpleBg,
                    label: 'Quiz',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.auto_stories_outlined,
                    color: AppColors.accentTeal,
                    background: AppColors.accentTealBg,
                    label: 'Word',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PracticeScreen(kind: 'word'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.shuffle,
                    color: AppColors.accentOrange,
                    background: AppColors.accentOrangeBg,
                    label: 'Random',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PracticeScreen(kind: 'idiom'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // --- Decks ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Decks',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(currentTabProvider.notifier).state = 1,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            decksAsync.when(
              loading: () => const LoadingSkeleton(lines: 4),
              error: (e, _) => ErrorState(
                message: 'Could not load decks',
                onRetry: () => ref.invalidate(decksProvider),
              ),
              data: (decks) {
                if (decks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      'No decks yet. Start learning to get flashcard decks.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < decks.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _DeckRow(deck: decks[i], index: i),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Bottom stats ---
            statsAsync.when(
              loading: () => const LoadingSkeleton(lines: 2),
              error: (_, _) => const SizedBox.shrink(),
              data: (stats) => Row(
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
                      value: '${stats.quizPct}%',
                      label: 'Quiz %',
                      color: AppColors.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Greeting (time-of-day + name) on the left, streak + settings on the right.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    final stats = ref.watch(statsProvider).valueOrNull;

    final hour = DateTime.now().hour;
    final (greeting, emoji) = switch (hour) {
      < 12 => ('Good morning', '☀️'),
      < 18 => ('Good afternoon', '⛅'),
      _ => ('Good evening', '\u{1F319}'),
    };
    final name = (auth.name != null && auth.name!.isNotEmpty)
        ? auth.name!
        : 'there';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                name,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (stats != null) ...[
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
          const SizedBox(width: AppSpacing.sm),
        ],
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }
}

/// Gradient hero card: cards-to-review count + start button.
class _ReviewHero extends ConsumerWidget {
  final int count;
  const _ReviewHero({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isDue = count > 0;

    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cards to review',
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$count',
                      style: textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      isDue
                          ? "Don't lose your progress!"
                          : 'All caught up \u{1F389}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.borderMd,
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isDue ? () => _startReview(context, ref) : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isDue ? 'Start Review' : 'Nothing due'),
                  if (isDue) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startReview(BuildContext context, WidgetRef ref) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _ReviewSessionScreen()));
  }
}

/// "Daily Goal X / N words" card with a percentage ring and progress bar.
class _DailyGoalCard extends ConsumerWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final goal = ref.watch(dailyGoalProvider);
    final pct = goal.target > 0
        ? (goal.done / goal.target).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDailyGoalPicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Daily Goal',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${goal.done} / ${goal.target} words',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ProgressBar(value: pct),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              ProgressRing(
                progress: pct,
                size: 52,
                strokeWidth: 5,
                child: Text(
                  '${(pct * 100).round()}%',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen review session (pushed from Home).
class _ReviewSessionScreen extends ConsumerWidget {
  const _ReviewSessionScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(review_providers.reviewCardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Could not load review cards',
          onRetry: () => ref.invalidate(review_providers.reviewCardsProvider),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No cards to review',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          final swipeCards = cards
              .map(
                (c) => SwipeCard(
                  front: c.term,
                  sub: c.pronunciation.isNotEmpty ? c.pronunciation : null,
                  back: [
                    c.meaning,
                    if (c.example.isNotEmpty) 'Example: ${c.example}',
                    if (c.persian.isNotEmpty) c.persian,
                  ].join('\n\n'),
                  term: c.term,
                ),
              )
              .toList();
          return SwipeSession(
            cards: swipeCards,
            onAnswer: (card, known) async {
              final client = ref.read(apiClientProvider);
              await client.post(
                ApiEndpoints.reviewAnswer,
                data: {'term': card.term, 'known': known},
              );
            },
            doneText: 'Review complete!',
            onFinish: () {
              ref.invalidate(review_providers.reviewCardsProvider);
              ref.invalidate(reviewCountProvider);
            },
          );
        },
      ),
    );
  }
}

/// Quick action tile: colored icon chip over a label.
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderXl,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              IconChip(icon: icon, color: color, background: background),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single deck row with a progress ring, counts, and a due pill.
class _DeckRow extends StatelessWidget {
  final dynamic deck;
  final int index;
  const _DeckRow({required this.deck, required this.index});

  static const _palette = [
    (AppColors.accentBlue, Icons.menu_book_outlined),
    (AppColors.accentPurple, Icons.school_outlined),
    (AppColors.accentTeal, Icons.link),
    (AppColors.accentOrange, Icons.bookmark_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pct = (deck.progressPct as int).clamp(0, 100) / 100.0;
    final (accent, icon) = _palette[index % _palette.length];

    return Card(
      child: InkWell(
        borderRadius: AppRadius.borderXl,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DeckDetailScreen(deckId: deck.id, deckName: deck.name),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ProgressRing(
                progress: pct,
                size: 44,
                strokeWidth: 4,
                color: accent,
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${deck.mastered}/${deck.total} mastered',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (deck.due > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      PillBadge(
                        text: '${deck.due} due',
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ],
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
