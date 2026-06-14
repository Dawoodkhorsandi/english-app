import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_study_screen.dart';

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;
  const DeckDetailScreen({super.key, required this.deckId, required this.deckName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(deckDetailProvider(deckId));

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading deck')),
        data: (detail) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${detail.mastered} mastered / ${detail.total} total'),
              if (detail.nextReview.isNotEmpty)
                Text('Next review: ${detail.nextReview}', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: 16),
              const Text('Box Distribution', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...detail.boxes.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Text('Box ${b.box}')),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: detail.total > 0 ? b.count / detail.total : 0,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${b.count}'),
                  ],
                ),
              )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DeckStudyScreen(deckId: deckId, deckName: deckName),
                  )),
                  child: const Text('Study Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
