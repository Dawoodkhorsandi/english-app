import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_detail_screen.dart';
import 'grammar_screen.dart';
import 'content_list_screen.dart';
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
          // --- Decks section ---
          const _SectionHeader(title: 'Decks'),
          const SizedBox(height: AppSpacing.sm),
          decksAsync.when(
            loading: () => const LoadingSkeleton(lines: 3),
            error: (e, s) => ErrorState(
              message: 'Could not load decks',
              onRetry: () => ref.invalidate(decksProvider),
            ),
            data: (decks) {
              if (decks.isEmpty) {
                return const EmptyState(
                  icon: Icons.library_books,
                  title: 'No decks yet',
                  subtitle: 'Decks appear as you learn new words.',
                );
              }
              return Column(
                children: decks
                    .map((d) => _DeckTile(deck: d))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // --- Grammar section ---
          const _SectionHeader(title: 'Grammar'),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GrammarScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_fix_high,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grammar Lessons',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Learn patterns from easy to advanced',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // --- Content section ---
          const _SectionHeader(title: 'Content'),
          const SizedBox(height: AppSpacing.sm),
          _ContentGrid(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  final dynamic deck;
  const _DeckTile({required this.deck});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = deck.total > 0 ? deck.mastered / deck.total : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DeckDetailScreen(deckId: deck.id, deckName: deck.name),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deck.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${deck.mastered}/${deck.total}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
              ),
              if (deck.due > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${deck.due} due for review',
                    style: textTheme.labelSmall?.copyWith(
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

class _ContentGrid extends StatelessWidget {
  static const _contentTypes = [
    _ContentType(
      kind: 'idiom',
      label: 'Idioms',
      icon: Icons.chat_bubble_outline,
      description: 'Common English expressions',
    ),
    _ContentType(
      kind: 'collocation',
      label: 'Collocations',
      icon: Icons.link,
      description: 'Words that go together',
    ),
    _ContentType(
      kind: 'story',
      label: 'Stories',
      icon: Icons.auto_stories,
      description: 'Short reading practice',
    ),
    _ContentType(
      kind: 'tip',
      label: 'Tips',
      icon: Icons.lightbulb_outline,
      description: 'Quick learning tips',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: _contentTypes.map((ct) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContentListScreen(
                  kind: ct.kind,
                  title: ct.label,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ct.icon,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ct.label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ct.description,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ContentType {
  final String kind;
  final String label;
  final IconData icon;
  final String description;
  const _ContentType({
    required this.kind,
    required this.label,
    required this.icon,
    required this.description,
  });
}
