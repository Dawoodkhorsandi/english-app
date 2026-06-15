import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/vocab_item.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/bookmark_star.dart';

enum _LibraryTab { words, bookmarks, dict }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _LibraryTab _tab = _LibraryTab.words;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  int _offset = 0;
  int _total = 0;
  final int _limit = 20;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Search bar ---
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _tab == _LibraryTab.dict
                  ? 'Search English \u2192 Persian...'
                  : 'Search words or meanings...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _offset = 0;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),

        // --- Segmented button ---
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_LibraryTab>(
              segments: const [
                ButtonSegment(
                  value: _LibraryTab.words,
                  label: Text('Words'),
                  icon: Icon(Icons.auto_stories, size: 18),
                ),
                ButtonSegment(
                  value: _LibraryTab.bookmarks,
                  label: Text('Bookmarks'),
                  icon: Icon(Icons.bookmark, size: 18),
                ),
                ButtonSegment(
                  value: _LibraryTab.dict,
                  label: Text('Dict'),
                  icon: Icon(Icons.translate, size: 18),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) {
                setState(() {
                  _tab = selection.first;
                  _searchQuery = '';
                  _searchController.clear();
                  _offset = 0;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // --- Content ---
        Expanded(
          child: _tab == _LibraryTab.dict
              ? _buildDictionary(context)
              : _buildWordList(context),
        ),
      ],
    );
  }

  Widget _buildWordList(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final params = VocabParams(
      q: _searchQuery,
      bookmarks: _tab == _LibraryTab.bookmarks,
      offset: _offset,
      limit: _limit,
    );
    final vocabAsync = ref.watch(vocabProvider(params));

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
        if (resp.items.isEmpty) {
          return EmptyState(
            icon: _tab == _LibraryTab.bookmarks
                ? Icons.bookmark_border
                : Icons.menu_book,
            title: _tab == _LibraryTab.bookmarks
                ? 'No bookmarks yet'
                : 'No words learned yet',
            subtitle: _tab == _LibraryTab.bookmarks
                ? 'Tap the star on any word to bookmark it.'
                : 'Start learning to build your vocabulary.',
          );
        }
        final showLoadMore = _offset + _limit < _total;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          itemCount: resp.items.length + (showLoadMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == resp.items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _offset += _limit),
                    child: const Text('Load more'),
                  ),
                ),
              );
            }
            return _wordRow(resp.items[i], textTheme, colorScheme);
          },
        );
      },
    );
  }

  Widget _wordRow(VocabItem w, TextTheme textTheme, ColorScheme colorScheme) {
    IconData masteryIcon;
    Color masteryColor;
    switch (w.mastery) {
      case 'mastered':
        masteryIcon = Icons.check_circle;
        masteryColor = const Color(0xFF22C55E);
        break;
      case 'learning':
        masteryIcon = Icons.auto_stories;
        masteryColor = colorScheme.primary;
        break;
      default:
        masteryIcon = Icons.fiber_new;
        masteryColor = colorScheme.outline;
    }

    return ListTile(
      leading: Icon(masteryIcon, color: masteryColor, size: 20),
      title: Text(
        w.term,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(w.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: BookmarkStar(term: w.term, initialBookmarked: w.bookmarked),
    );
  }

  Widget _buildDictionary(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                              borderRadius: BorderRadius.circular(4),
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
                        child: Text(
                          r['persian'],
                          style: textTheme.bodyLarge,
                        ),
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
