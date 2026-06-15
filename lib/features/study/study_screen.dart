import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_detail_screen.dart';
import 'grammar_screen.dart';
import 'practice_screen.dart';
import '../quiz/quiz_screen.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../core/theme/app_spacing.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final decksAsync = ref.watch(decksProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(decksProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            '\u{1F4DA} Study',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice now',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.chipGap,
                    runSpacing: AppSpacing.chipGap,
                    children: [
                      _practiceChip(context, '\u{1F9E9}', 'Quiz', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuizScreen(),
                          ),
                        );
                      }),
                      _practiceChip(context, '\u{1F4D8}', 'New word', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PracticeScreen(kind: 'word'),
                          ),
                        );
                      }),
                      _practiceChip(context, '\u{1F4AC}', 'Idiom', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PracticeScreen(kind: 'idiom'),
                          ),
                        );
                      }),
                      _practiceChip(context, '\u{1F517}', 'Collocation', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const PracticeScreen(kind: 'collocation'),
                          ),
                        );
                      }),
                      _practiceChip(context, '\u{1F4D6}', 'Story', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PracticeScreen(kind: 'story'),
                          ),
                        );
                      }),
                      _practiceChip(context, '\u{1F4A1}', 'Tip', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PracticeScreen(kind: 'tip'),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GrammarScreen()),
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grammar lessons',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Learn one pattern at a time, from easy to advanced.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          decksAsync.when(
            loading: () => const LoadingSkeleton(lines: 5),
            error: (e, s) => ErrorState(
              message: 'Could not load decks',
              onRetry: () => ref.invalidate(decksProvider),
            ),
            data: (decks) {
              if (decks.isEmpty) {
                return const EmptyState(
                  icon: Icons.library_books,
                  title: 'No decks available.',
                  subtitle: 'Decks will appear here once you start learning.',
                );
              }
              return Column(
                children:
                    decks.map((d) => _deckCard(context, d, textTheme)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _practiceChip(
    BuildContext context,
    String emoji,
    String label,
    VoidCallback? onTap,
  ) {
    return ActionChip(
      avatar: Text(emoji),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _deckCard(BuildContext context, dynamic deck, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: ListTile(
        title: Text(
          deck.name,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${deck.mastered} mastered'),
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
