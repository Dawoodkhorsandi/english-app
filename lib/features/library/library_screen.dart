import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/vocab_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/bookmark_star.dart';
import '../../shared/widgets/bottom_sheet_word.dart';
import '../../shared/widgets/segmented_tabs.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // 0=All, 1=New, 2=Learning, 3=Mastered
  int _masteryFilter = 0;
  bool _bookmarksOnly = false;
  bool _dictMode = false;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  int _offset = 0;
  int _total = 0;
  final int _limit = 20;

  static const _masteryByIndex = [null, 'new', 'learning', 'mastered'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
        _offset = 0;
      });
    });
  }

  void _resetSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _offset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: Text(
              'Library',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // --- Search bar ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _dictMode
                    ? 'Search English → Persian...'
                    : 'Search words...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _resetSearch,
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // --- Filter row ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _dictMode
                      ? _DictBanner()
                      : SegmentedTabs(
                          selectedIndex: _masteryFilter,
                          onChanged: (i) => setState(() => _masteryFilter = i),
                          tabs: const [
                            SegmentedTab(label: 'All'),
                            SegmentedTab(label: 'New'),
                            SegmentedTab(label: 'Learning'),
                            SegmentedTab(label: 'Mastered'),
                          ],
                        ),
                ),
                if (!_dictMode) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _ToggleIcon(
                    icon: _bookmarksOnly
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    active: _bookmarksOnly,
                    onTap: () => setState(() {
                      _bookmarksOnly = !_bookmarksOnly;
                      _offset = 0;
                    }),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                _ToggleIcon(
                  icon: Icons.translate,
                  active: _dictMode,
                  onTap: () => setState(() {
                    _dictMode = !_dictMode;
                    _resetSearch();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // --- Content ---
          Expanded(
            child: _dictMode
                ? _buildDictionary(context, textTheme, colorScheme)
                : _buildWordList(context, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList(BuildContext context, TextTheme textTheme) {
    final params = VocabParams(
      q: _searchQuery,
      bookmarks: _bookmarksOnly,
      offset: _offset,
      limit: _limit,
    );
    final vocabAsync = ref.watch(vocabProvider(params));
    final masteryFilter = _masteryByIndex[_masteryFilter];

    return vocabAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: LoadingSkeleton(lines: 6),
      ),
      error: (e, _) => ErrorState(
        message: 'Could not load words',
        onRetry: () => ref.invalidate(vocabProvider(params)),
      ),
      data: (resp) {
        _total = resp.total;
        final items = masteryFilter == null
            ? resp.items
            : resp.items.where((w) => w.mastery == masteryFilter).toList();

        if (resp.items.isEmpty) {
          return EmptyState(
            icon: _bookmarksOnly ? Icons.bookmark_border : Icons.menu_book,
            title: _bookmarksOnly ? 'No bookmarks yet' : 'No words learned yet',
            subtitle: _bookmarksOnly
                ? 'Tap the star on any word to bookmark it.'
                : 'Start learning to build your vocabulary.',
          );
        }
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.filter_alt_off,
            title: 'No words match this filter',
            subtitle: 'Try a different filter on this page.',
          );
        }

        final showLoadMore = _offset + _limit < _total;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          itemCount: items.length + (showLoadMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            if (i == items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _offset += _limit),
                    child: const Text('Load more'),
                  ),
                ),
              );
            }
            return _WordCard(
              item: items[i],
              onTap: () => _showWordDetail(context, items[i]),
            );
          },
        );
      },
    );
  }

  void _showWordDetail(BuildContext context, VocabItem w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final cardAsync = ref.watch(vocabCardProvider(w.term));
          return cardAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.term,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(w.meaning),
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            error: (_, _) => WordBottomSheet(term: w.term, meaning: w.meaning),
            data: (card) => WordBottomSheet(
              term: card.term,
              meaning: card.meaning,
              persian: card.meaning,
              example: card.text,
              onOpenDictionary: () {
                Navigator.of(context).pop();
                setState(() {
                  _dictMode = true;
                  _searchController.text = w.term;
                  _searchQuery = w.term;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDictionary(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (_searchQuery.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search for a word',
        subtitle: 'Type an English word to see its Persian meaning.',
      );
    }

    final dictAsync = ref.watch(dictionaryProvider(_searchQuery));
    return dictAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: LoadingSkeleton(lines: 4),
      ),
      error: (e, _) => ErrorState(
        message: 'Could not look up word',
        onRetry: () => ref.invalidate(dictionaryProvider(_searchQuery)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No results found',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final r = results[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r['word'] ?? '',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((r['pos'] ?? '').isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              r['pos'],
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((r['pronunciation'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          r['pronunciation'],
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    if ((r['persian'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(r['persian'], style: textTheme.bodyLarge),
                      ),
                    if ((r['definition'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          r['definition'],
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    if ((r['example'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          r['example'],
                          style: textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Banner shown in the filter row when dictionary mode is active.
class _DictBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        'Dictionary',
        style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}

class _ToggleIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: active
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadius.borderFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderFull,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: 20,
            color: active
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final VocabItem item;
  final VoidCallback onTap;
  const _WordCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.term,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatusPill(mastery: item.mastery),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.meaning,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              BookmarkStar(term: item.term, initialBookmarked: item.bookmarked),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String mastery;
  const _StatusPill({required this.mastery});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final (label, color) = switch (mastery) {
      'mastered' => ('MASTERED', AppColors.success),
      'learning' => ('LEARNING', AppColors.accentBlue),
      _ => ('NEW', colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
