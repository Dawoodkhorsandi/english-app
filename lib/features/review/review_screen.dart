import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart' as review_providers;
import 'widgets/swipe_card.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final cardsAsync = ref.watch(review_providers.reviewCardsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              '🧠 Review',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: cardsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: LoadingSkeleton(lines: 5),
              ),
              error: (e, s) => ErrorState(
                message: 'Could not load review cards',
                onRetry: () =>
                    ref.invalidate(review_providers.reviewCardsProvider),
              ),
              data: (cards) {
                if (cards.isEmpty) {
                  return const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No cards to review.',
                    subtitle: 'Come back later when new cards are available!',
                  );
                }
                final swipeCards = cards
                    .map(
                      (c) => SwipeCard(
                        front: c.term,
                        sub: c.pronunciation.isNotEmpty
                            ? c.pronunciation
                            : null,
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
                  doneText: 'Review complete! Great job!',
                  onFinish: () =>
                      ref.invalidate(review_providers.reviewCardsProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
