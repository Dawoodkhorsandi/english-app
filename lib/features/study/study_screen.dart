import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_detail_screen.dart';
import 'grammar_screen.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(decksProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '📚 Study',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Practice now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _practiceChip(context, '🧩', 'Quiz', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _QuizPlaceholder(),
                          ),
                        );
                      }),
                      _practiceChip(context, '📘', 'New word', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _PracticePlaceholder(
                              kind: 'word',
                              emoji: '📘',
                              title: 'New Word',
                            ),
                          ),
                        );
                      }),
                      _practiceChip(context, '💬', 'Idiom', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _PracticePlaceholder(
                              kind: 'idiom',
                              emoji: '💬',
                              title: 'Idiom',
                            ),
                          ),
                        );
                      }),
                      _practiceChip(context, '🔗', 'Collocation', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _PracticePlaceholder(
                              kind: 'collocation',
                              emoji: '🔗',
                              title: 'Collocation',
                            ),
                          ),
                        );
                      }),
                      _practiceChip(context, '📖', 'Story', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _PracticePlaceholder(
                              kind: 'story',
                              emoji: '📖',
                              title: 'Story',
                            ),
                          ),
                        );
                      }),
                      _practiceChip(context, '💡', 'Tip', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _PracticePlaceholder(
                              kind: 'tip',
                              emoji: '💡',
                              title: 'Tip',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GrammarScreen())),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grammar lessons',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn one pattern at a time, from easy to advanced.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                children: decks.map((d) => _deckCard(context, d)).toList(),
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

  Widget _deckCard(BuildContext context, dynamic deck) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          deck.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
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

class _QuizPlaceholder extends StatelessWidget {
  const _QuizPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: const Center(child: Text('Open Quiz from the Study tab')),
    );
  }
}

class _PracticePlaceholder extends StatelessWidget {
  final String kind;
  final String emoji;
  final String title;
  const _PracticePlaceholder({
    required this.kind,
    required this.emoji,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$emoji $title')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practice your $kind skills here.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
