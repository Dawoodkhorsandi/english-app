import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import 'models/feed_post.dart';

/// Immutable state for the social feed.
class FeedState {
  final List<FeedPost> posts;
  final bool loading; // initial / refresh load in flight
  final bool loadingMore; // pagination load in flight
  final bool hasMore;
  final int cursor; // content_pool.id cursor; 0 = start
  final Object? error;

  const FeedState({
    this.posts = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.cursor = 0,
    this.error,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? cursor,
    Object? error,
    bool clearError = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the social feed: paginated content from `/api/feed`, with a quiz and a
/// due-review post injected near the top, plus word lookups from the compose FAB.
/// App-scoped (not autoDispose) so the feed survives tab switches.
final feedControllerProvider = NotifierProvider<FeedController, FeedState>(
  FeedController.new,
);

const int _pageSize = 10;

class FeedController extends Notifier<FeedState> {
  bool _bootstrapped = false;

  @override
  FeedState build() {
    if (!_bootstrapped) {
      _bootstrapped = true;
      Future.microtask(loadInitial);
    }
    return const FeedState(loading: true);
  }

  ApiClient get _client => ref.read(apiClientProvider);

  /// First load (and the empty-state retry): a page of content plus an injected
  /// quiz and due-review post at the top when available.
  Future<void> loadInitial() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final page = await _fetchPage(0);
      final injected = await _fetchInjected();
      state = FeedState(
        posts: [...injected, ...page.$1],
        loading: false,
        hasMore: page.$2 != null,
        cursor: page.$2 ?? 0,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Pull-to-refresh: reload from the newest, re-injecting quiz/review.
  Future<void> refresh() async {
    try {
      final page = await _fetchPage(0);
      final injected = await _fetchInjected();
      state = FeedState(
        posts: [...injected, ...page.$1],
        loading: false,
        hasMore: page.$2 != null,
        cursor: page.$2 ?? 0,
      );
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }

  /// Infinite scroll: append the next page.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.cursor == 0) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _fetchPage(state.cursor);
      state = state.copyWith(
        posts: [...state.posts, ...page.$1],
        loadingMore: false,
        hasMore: page.$2 != null,
        cursor: page.$2 ?? state.cursor,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e);
    }
  }

  /// Compose-FAB word lookup → prepend the resulting word post.
  Future<void> lookup(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    try {
      final r = await _client.get(
        ApiEndpoints.lookup,
        queryParameters: {'term': trimmed},
      );
      final data = r.data as Map;
      if (data['available'] == true) {
        final post = FeedPost(
          id: FeedPost.nextLocalId(),
          kind: PostKind.word,
          time: DateTime.now(),
          html: (data['text'] ?? '') as String,
          term: (data['term'] ?? '') as String,
        );
        state = state.copyWith(posts: [post, ...state.posts]);
      }
    } catch (_) {
      // Best-effort; a failed lookup just adds nothing.
    }
  }

  // ---- interactions -------------------------------------------------------

  Future<void> answerQuiz(String postId, int option) async {
    final quiz = _byId(postId)?.quiz;
    if (quiz == null || quiz.isAnswered) return;
    quiz.answered = option;
    _emit();
    try {
      await _client.post(
        ApiEndpoints.quizAnswer,
        data: {
          'word': quiz.word,
          'correct': quiz.correct,
          'exp': quiz.exp,
          'token': quiz.token,
          'answer': option,
        },
      );
    } catch (_) {}
  }

  Future<void> answerSrs(String postId, bool known) async {
    final srs = _byId(postId)?.srs;
    if (srs == null || srs.isAnswered) return;
    srs.known = known;
    _emit();
    try {
      await _client.post(
        ApiEndpoints.reviewAnswer,
        data: {'term': srs.term, 'known': known},
      );
    } catch (_) {}
  }

  /// Save: real bookmark for word posts (`/api/bookmark`); local toggle otherwise.
  Future<void> toggleBookmark(String postId) async {
    final post = _byId(postId);
    if (post == null) return;
    post.bookmarked = !post.bookmarked;
    _emit();
    final term = post.term;
    if (term == null || term.isEmpty) return; // local-only for non-words
    try {
      await _client.post(
        ApiEndpoints.bookmark,
        data: {'term': term, 'on': post.bookmarked},
      );
    } catch (_) {
      post.bookmarked = !post.bookmarked;
      _emit();
    }
  }

  /// Like — local/cosmetic only (no backend).
  void toggleLike(String postId) {
    final post = _byId(postId);
    if (post == null) return;
    post.liked = !post.liked;
    post.likeCount += post.liked ? 1 : -1;
    if (post.likeCount < 0) post.likeCount = 0;
    _emit();
  }

  /// Comment — local/cosmetic only (no backend).
  void addComment(String postId, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final post = _byId(postId);
    if (post == null) return;
    post.comments.add(t);
    _emit();
  }

  /// Share via the system share sheet.
  Future<void> share(String postId) async {
    final post = _byId(postId);
    if (post == null) return;
    final body = post.drill != null && post.drill!.pages.isNotEmpty
        ? post.drill!.pages.first
        : post.html;
    final plain = _stripHtml(body);
    if (plain.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: plain));
  }

  // ---- helpers ------------------------------------------------------------

  /// Fetches one content page; returns (posts, nextCursor) where a null cursor
  /// means there is no further page.
  Future<(List<FeedPost>, int?)> _fetchPage(int cursor) async {
    final r = await _client.get(
      ApiEndpoints.feed,
      queryParameters: {'limit': _pageSize, 'cursor': cursor},
    );
    final data = r.data as Map;
    final items = (data['items'] as List? ?? const [])
        .map((j) => FeedPost.fromFeedJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    final next = data['next_cursor'];
    return (items, next is int ? next : null);
  }

  /// Fetches a quiz and one due-review card to inject at the top of the feed.
  Future<List<FeedPost>> _fetchInjected() async {
    final injected = <FeedPost>[];
    try {
      final r = await _client.get(
        ApiEndpoints.reviewNext,
        queryParameters: {'limit': 1},
      );
      final items = (r.data['items'] as List? ?? const []);
      if (items.isNotEmpty) {
        final c = Map<String, dynamic>.from(items.first as Map);
        injected.add(
          FeedPost(
            id: FeedPost.nextLocalId(),
            kind: PostKind.srs,
            time: DateTime.now(),
            srs: SrsPayload(
              term: (c['term'] ?? '') as String,
              meaning: (c['meaning'] ?? '') as String,
              pronunciation: (c['pronunciation'] ?? '') as String,
              persian: (c['persian'] ?? '') as String,
              example: (c['example'] ?? '') as String,
            ),
          ),
        );
      }
    } catch (_) {}
    try {
      final r = await _client.get(ApiEndpoints.quizNext);
      final data = r.data as Map;
      if (data['available'] == true) {
        injected.add(
          FeedPost(
            id: FeedPost.nextLocalId(),
            kind: PostKind.quiz,
            time: DateTime.now(),
            quiz: QuizPayload(
              prompt: (data['prompt'] ?? '') as String,
              options: List<String>.from(data['options'] ?? const []),
              word: (data['word'] ?? '') as String,
              correct: (data['correct'] ?? 0) as int,
              exp: (data['exp'] ?? 0) as int,
              token: (data['token'] ?? '') as String,
            ),
          ),
        );
      }
    } catch (_) {}
    return injected;
  }

  FeedPost? _byId(String id) {
    for (final p in state.posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Posts hold mutable payloads; emit a new list reference so widgets rebuild.
  void _emit() => state = state.copyWith(posts: [...state.posts]);

  static String _stripHtml(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&amp;', '&').trim();
}
