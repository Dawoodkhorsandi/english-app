import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../review/widgets/swipe_card.dart';
import 'providers.dart';

class DeckStudyScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;
  const DeckStudyScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final cardsAsync = ref.watch(deckStudyProvider(deckId));

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: AppSpacing.huge),
              const SizedBox(height: AppSpacing.lg),
              Text('Could not load cards', style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => ref.invalidate(deckStudyProvider(deckId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Text('No cards to study.', style: textTheme.bodyLarge),
            );
          }
          return SwipeSession(
            cards: cards
                .map(
                  (c) => SwipeCard(
                    front: c.term,
                    sub: c.pronunciation.isNotEmpty ? c.pronunciation : null,
                    back: [
                      c.definition,
                      if (c.example.isNotEmpty) 'Example: ${c.example}',
                      if (c.persian.isNotEmpty) c.persian,
                      if (c.mnemonic.isNotEmpty) 'Mnemonic: ${c.mnemonic}',
                    ].join('\n\n'),
                    term: c.term,
                  ),
                )
                .toList(),
            onAnswer: (card, known) async {
              final client = ref.read(apiClientProvider);
              await client.post(
                '/api/decks/swipe',
                data: {'deck': deckId, 'term': card.term, 'known': known},
              );
            },
            doneText: 'Deck study complete!',
          );
        },
      ),
    );
  }
}
