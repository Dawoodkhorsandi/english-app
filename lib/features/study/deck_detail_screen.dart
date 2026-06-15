import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_study_screen.dart';
import '../../core/theme/app_spacing.dart';

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;
  const DeckDetailScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final detailAsync = ref.watch(deckDetailProvider(deckId));

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading deck')),
        data: (detail) => Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.name,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('${detail.mastered} mastered / ${detail.total} total'),
              if (detail.nextReview.isNotEmpty)
                Text(
                  'Next review: ${detail.nextReview}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Box Distribution',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...detail.boxes.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(width: 60, child: Text('Box ${b.box}')),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: detail.total > 0 ? b.count / detail.total : 0,
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('${b.count}'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DeckStudyScreen(deckId: deckId, deckName: deckName),
                    ),
                  ),
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
