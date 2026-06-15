import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/vocab_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/bookmark_star.dart';

enum LibraryFilter {
  all,
  bookmarks,
  idiom,
  collocation,
  story,
  tip,
  quiz,
  dict,
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;
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
      setState(() {
        _searchQuery = value;
        _offset = 0;
      });
    });
  }

  void _loadMore() {
    setState(() => _offset += _limit);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📚 Library',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_filter == LibraryFilter.dict)
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search English -> Persian...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            )
          else if (_filter == LibraryFilter.all ||
              _filter == LibraryFilter.bookmarks)
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search words or meanings...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: LibraryFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.chipGap),
                      child: FilterChip(
                        label: Text(_filterLabel(f)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() {
                          _filter = f;
                          _searchQuery = '';
                          _searchController.clear();
                          _offset = 0;
                        }),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _buildContent(textTheme, colorScheme)),
        ],
      ),
    );
  }

  String _filterLabel(LibraryFilter f) {
    switch (f) {
      case LibraryFilter.all:
        return 'Words';
      case LibraryFilter.bookmarks:
        return 'Bookmarks';
      case LibraryFilter.idiom:
        return 'Idioms';
      case LibraryFilter.collocation:
        return 'Collocations';
      case LibraryFilter.story:
        return 'Stories';
      case LibraryFilter.tip:
        return 'Tips';
      case LibraryFilter.quiz:
        return 'Quizzes';
      case LibraryFilter.dict:
        return 'Dict';
    }
  }

  Widget _buildContent(TextTheme textTheme, ColorScheme colorScheme) {
    switch (_filter) {
      case LibraryFilter.dict:
        return _buildDictionary(textTheme, colorScheme);
      case LibraryFilter.quiz:
        return _buildQuizHistory(textTheme, colorScheme);
      case LibraryFilter.idiom:
      case LibraryFilter.collocation:
      case LibraryFilter.story:
      case LibraryFilter.tip:
        return _buildContentList(_filter.name, textTheme, colorScheme);
      default:
        return _buildWordList(textTheme);
    }
  }

  Widget _buildWordList(TextTheme textTheme) {
    final params = VocabParams(
      q: _searchQuery,
      bookmarks: _filter == LibraryFilter.bookmarks,
      offset: _offset,
      limit: _limit,
    );
    final vocabAsync = ref.watch(vocabProvider(params));
    return vocabAsync.when(
      loading: () => const LoadingSkeleton(lines: 5),
      error: (e, s) => ErrorState(
        message: 'Could not load words',
        onRetry: () => ref.invalidate(vocabProvider(params)),
      ),
      data: (resp) {
        _total = resp.total;
        if (resp.items.isEmpty) {
          return EmptyState(
            icon: _filter == LibraryFilter.bookmarks
                ? Icons.star_border
                : Icons.menu_book,
            title: _filter == LibraryFilter.bookmarks
                ? 'No bookmarks yet.'
                : 'No words learned yet.',
            subtitle: 'Start learning to build your vocabulary.',
          );
        }
        final showLoadMore = _offset + _limit < _total;
        return ListView.builder(
          itemCount: resp.items.length + (showLoadMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == resp.items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  ),
                ),
              );
            }
            return _wordRow(resp.items[i], textTheme);
          },
        );
      },
    );
  }

  Widget _wordRow(VocabItem w, TextTheme textTheme) {
    final masteryIcon = w.mastery == 'mastered'
        ? '✅'
        : w.mastery == 'learning'
        ? '📖'
        : '🆕';
    return ListTile(
      leading: Text(masteryIcon),
      title: Text(
        w.term,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(w.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: BookmarkStar(term: w.term, initialBookmarked: w.bookmarked),
    );
  }

  Widget _buildContentList(
    String kind,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final contentAsync = ref.watch(contentProvider(kind));
    return contentAsync.when(
      loading: () => const LoadingSkeleton(lines: 5),
      error: (e, s) => ErrorState(
        message: 'Could not load $kind',
        onRetry: () => ref.invalidate(contentProvider(kind)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.article_outlined,
            title: 'No $kind items yet.',
            subtitle: 'They will appear here once available.',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return ListTile(
              title: Text(
                item.term,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item.meaning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                item.sentAt,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizHistory(TextTheme textTheme, ColorScheme colorScheme) {
    final quizAsync = ref.watch(quizHistoryProvider);
    return quizAsync.when(
      loading: () => const LoadingSkeleton(lines: 5),
      error: (e, s) => ErrorState(
        message: 'Could not load quiz history',
        onRetry: () => ref.invalidate(quizHistoryProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.quiz_outlined,
            title: 'No quiz attempts yet.',
            subtitle: 'Take a quiz to see your history here.',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final q = items[i];
            return ListTile(
              leading: Icon(
                q.correct ? Icons.check_circle : Icons.cancel,
                color: q.correct ? AppColors.success : AppColors.danger,
              ),
              title: Text(q.word, style: textTheme.bodyLarge),
              trailing: Text(
                q.answeredAt,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDictionary(TextTheme textTheme, ColorScheme colorScheme) {
    final dictAsync = ref.watch(dictionaryProvider(_searchQuery));
    if (_searchQuery.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search for a word',
        subtitle: 'Type an English word to see its Persian meaning.',
      );
    }
    return dictAsync.when(
      loading: () => const LoadingSkeleton(lines: 5),
      error: (e, s) => ErrorState(
        message: 'Could not look up word',
        onRetry: () => ref.invalidate(dictionaryProvider(_searchQuery)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No results found.',
          );
        }
        return ListView.builder(
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
                          Text(
                            r['pos'],
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((r['pronunciation'] ?? '').isNotEmpty)
                      Text(
                        r['pronunciation'],
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    if ((r['persian'] ?? '').isNotEmpty)
                      Text(r['persian'], style: textTheme.bodyLarge),
                    if ((r['definition'] ?? '').isNotEmpty)
                      Text(r['definition'], style: textTheme.bodyMedium),
                    if ((r['example'] ?? '').isNotEmpty)
                      Text(
                        r['example'],
                        style: textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.outline,
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
