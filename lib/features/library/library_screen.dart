import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/vocab_item.dart';
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Library',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: LibraryFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
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
          const SizedBox(height: 12),
          Expanded(child: _buildContent()),
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

  Widget _buildContent() {
    switch (_filter) {
      case LibraryFilter.dict:
        return _buildDictionary();
      case LibraryFilter.quiz:
        return _buildQuizHistory();
      case LibraryFilter.idiom:
      case LibraryFilter.collocation:
      case LibraryFilter.story:
      case LibraryFilter.tip:
        return _buildContentList(_filter.name);
      default:
        return _buildWordList();
    }
  }

  Widget _buildWordList() {
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  ),
                ),
              );
            }
            return _wordRow(resp.items[i]);
          },
        );
      },
    );
  }

  Widget _wordRow(VocabItem w) {
    final masteryIcon = w.mastery == 'mastered'
        ? '✅'
        : w.mastery == 'learning'
        ? '📖'
        : '🆕';
    return ListTile(
      leading: Text(masteryIcon),
      title: Text(w.term, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(w.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: BookmarkStar(term: w.term, initialBookmarked: w.bookmarked),
    );
  }

  Widget _buildContentList(String kind) {
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                item.meaning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                item.sentAt,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizHistory() {
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
                color: q.correct ? Colors.green : Colors.red,
              ),
              title: Text(q.word),
              trailing: Text(
                q.answeredAt,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDictionary() {
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
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r['word'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((r['pos'] ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            r['pos'],
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((r['pronunciation'] ?? '').isNotEmpty)
                      Text(
                        r['pronunciation'],
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    if ((r['persian'] ?? '').isNotEmpty)
                      Text(r['persian'], style: const TextStyle(fontSize: 16)),
                    if ((r['definition'] ?? '').isNotEmpty)
                      Text(r['definition']),
                    if ((r['example'] ?? '').isNotEmpty)
                      Text(
                        r['example'],
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).hintColor,
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
