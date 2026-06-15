import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../profile/providers.dart';
import '../study/providers.dart';
import '../review/providers.dart' as review_providers;
import '../review/widgets/swipe_card.dart';
import '../quiz/quiz_screen.dart';
import '../study/practice_screen.dart';
import '../study/deck_detail_screen.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statsAsync = ref.watch(statsProvider);
    final decksAsync = ref.watch(decksProvider);
    final reviewCountAsync = ref.watch(reviewCountProvider);
    final auth = ref.watch(authProvider);

    return RefreshIndicator(
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
          // --- Greeting ---
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.name != null && auth.name!.isNotEmpty
                      ? 'Hello, ${auth.name}'
                      : 'Hello',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: stats.currentStreak > 0
                          ? Colors.deepOrange
                          : colorScheme.outline,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${stats.currentStreak} day streak',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Review Card (hero) ---
          reviewCountAsync.when(
            loading: () => const LoadingSkeleton(lines: 3),
            error: (e, _) => ErrorState(
              message: 'Could not load review count',
              onRetry: () => ref.invalidate(reviewCountProvider),
            ),
            data: (count) => _ReviewCard(count: count),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Quick Practice ---
          Text(
            'Quick Practice',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.quiz_outlined,
                  label: 'Quiz',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const QuizScreen())),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _QuickAction(
                  icon: Icons.auto_stories_outlined,
                  label: 'New Word',
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
          Text(
            'Your Decks',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    'No decks yet. Start learning to get flashcard decks.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return Column(
                children: decks
                    .map((d) => _DeckRow(deck: d, context: context))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- This Week stats ---
          statsAsync.when(
            loading: () => const LoadingSkeleton(lines: 2),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StatChip(label: 'Words', value: '${stats.words}'),
                    const SizedBox(width: AppSpacing.sm),
                    _StatChip(label: 'Mastered', value: '${stats.mastered}'),
                    const SizedBox(width: AppSpacing.sm),
                    _StatChip(label: 'Quiz', value: '${stats.quizPct}%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Hero review card with due count and start button.
class _ReviewCard extends ConsumerWidget {
  final int count;
  const _ReviewCard({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDue = count > 0;

    return Card(
      color: isDue ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDue ? Icons.style_outlined : Icons.check_circle_outline,
                  color: isDue
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Review',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDue ? colorScheme.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isDue
                  ? '$count card${count == 1 ? '' : 's'} due today'
                  : 'All caught up! Come back later.',
              style: textTheme.bodyMedium?.copyWith(
                color: isDue
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (isDue) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _startReview(context, ref),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startReview(BuildContext context, WidgetRef ref) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _ReviewSessionScreen()));
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

/// Quick action card for Quiz / Word / Random.
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single deck row with progress bar.
class _DeckRow extends StatelessWidget {
  final dynamic deck;
  final BuildContext context;
  const _DeckRow({required this.deck, required this.context});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pct = (deck.progressPct as int).clamp(0, 100) / 100.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        title: Text(
          deck.name,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${deck.mastered}/${deck.total} mastered'
              '${deck.due > 0 ? ' \u00b7 ${deck.due} due' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DeckDetailScreen(deckId: deck.id, deckName: deck.name),
          ),
        ),
      ),
    );
  }
}

/// Compact stat chip.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
