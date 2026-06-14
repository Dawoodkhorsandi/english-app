import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
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
    final cardsAsync = ref.watch(deckStudyProvider(deckId));

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Could not load cards'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(deckStudyProvider(deckId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (cards) {
          if (cards.isEmpty)
            return const Center(child: Text('No cards to study.'));
          return _SwipeSession(
            cards: cards
                .map(
                  (c) => _SwipeCard(
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
            onFinish: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }
}

class _SwipeCard {
  final String front;
  final String? sub;
  final String back;
  final String term;
  _SwipeCard({
    required this.front,
    this.sub,
    required this.back,
    required this.term,
  });
}

class _SwipeSession extends StatefulWidget {
  final List<_SwipeCard> cards;
  final Future<void> Function(_SwipeCard card, bool known) onAnswer;
  final String doneText;
  final VoidCallback? onFinish;

  const _SwipeSession({
    required this.cards,
    required this.onAnswer,
    this.doneText = 'Session complete!',
    this.onFinish,
  });

  @override
  State<_SwipeSession> createState() => _SwipeSessionState();
}

class _SwipeSessionState extends State<_SwipeSession> {
  late List<_SwipeCard> _queue;
  int _knownCount = 0;
  bool _finished = false;
  bool _flipped = false;
  double _dx = 0;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.cards);
  }

  void _commit(bool known) async {
    if (_queue.isEmpty) return;
    final card = _queue.first;
    HapticFeedback.mediumImpact();
    setState(() {
      if (known) _knownCount++;
      if (known) _knownCount++;
      _queue.removeAt(0);
      _dx = 0;
      _flipped = false;
    });
    try {
      await widget.onAnswer(card, known);
    } catch (e) {
      _queue.insert(0, card);
      if (known) _knownCount--;
    }
    if (_queue.isEmpty) {
      setState(() => _finished = true);
      HapticFeedback.heavyImpact();
      widget.onFinish?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _buildCompletion();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_queue.length} remaining',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              const Spacer(),
              Text(
                '$_knownCount known',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() => _dx += d.delta.dx),
            onHorizontalDragEnd: (d) {
              if (_dx > 90) {
                _commit(true);
              } else if (_dx < -90) {
                _commit(false);
              } else {
                setState(() => _dx = 0);
              }
            },
            onTap: () => setState(() => _flipped = !_flipped),
            child: Container(
              margin: const EdgeInsets.all(16),
              transform: Matrix4.translationValues(_dx, 0, 0)
                ..rotateZ(_dx * 0.001),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_flipped) ...[
                            Text(
                              _queue.first.back,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 17),
                            ),
                          ] else ...[
                            Text(
                              _queue.first.front,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_queue.first.sub != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _queue.first.sub!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                          Text(
                            _flipped ? 'Tap to see front' : 'Tap to flip',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_dx > 30)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Opacity(
                        opacity: (_dx / 90).clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'KNEW IT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_dx < -30)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Opacity(
                        opacity: (-_dx / 90).clamp(0.0, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FORGOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _commit(false),
                icon: const Icon(Icons.close),
                label: const Text('Forgot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _commit(true),
                icon: const Icon(Icons.check),
                label: const Text('Knew it'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    final pct = widget.cards.isNotEmpty
        ? (_knownCount / widget.cards.length)
        : 0.0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.doneText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$_knownCount known / ${widget.cards.length - _knownCount} forgot',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
