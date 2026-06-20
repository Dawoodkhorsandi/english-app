/// The kind of feed post — mirrors the bot's content kinds plus the interactive
/// quiz/SRS cards injected into the feed.
enum PostKind { word, drill, idiom, collocation, story, tip, quiz, srs, text }

/// Interactive payload for an in-feed multiple-choice quiz (from /api/quiz/next).
class QuizPayload {
  final String prompt;
  final List<String> options;
  final String word;
  final int correct;
  final int exp;
  final String token;

  /// The option the user tapped, or null while unanswered.
  int? answered;

  QuizPayload({
    required this.prompt,
    required this.options,
    required this.word,
    required this.correct,
    required this.exp,
    required this.token,
    this.answered,
  });

  bool get isAnswered => answered != null;
}

/// Interactive payload for a spaced-repetition review card (from /api/review/next).
class SrsPayload {
  final String term;
  final String meaning;
  final String pronunciation;
  final String persian;
  final String example;

  /// True/false once the user taps Knew it / Forgot; null while unanswered.
  bool? known;

  SrsPayload({
    required this.term,
    required this.meaning,
    this.pronunciation = '',
    this.persian = '',
    this.example = '',
    this.known,
  });

  bool get isAnswered => known != null;
}

/// A grammar drill split into pages, shown as a swipeable carousel.
class DrillPayload {
  final List<String> pages;
  DrillPayload({required this.pages});
  int get pageCount => pages.length;
}

/// A single post in the social feed.
class FeedPost {
  final String id;
  final PostKind kind;
  final DateTime time;

  /// Inline-HTML body for word/idiom/collocation/story/tip/text posts.
  final String html;

  /// The vocabulary term (word posts), used for Save/bookmark.
  final String? term;

  final QuizPayload? quiz;
  final SrsPayload? srs;
  final DrillPayload? drill;

  /// Server-backed save state (words only); local toggle otherwise.
  bool bookmarked;

  // Local/cosmetic social state (no backend).
  bool liked;
  int likeCount;
  final List<String> comments;

  FeedPost({
    required this.id,
    required this.kind,
    required this.time,
    this.html = '',
    this.term,
    this.quiz,
    this.srs,
    this.drill,
    this.bookmarked = false,
    this.liked = false,
    this.likeCount = 0,
    List<String>? comments,
  }) : comments = comments ?? [];

  /// Builds a content post from one `/api/feed` item.
  factory FeedPost.fromFeedJson(Map<String, dynamic> json) {
    final kind = _kindFromString(json['kind'] as String? ?? 'text');
    final text = (json['text'] ?? '') as String;
    final ts = json['ts'];
    final time = ts is int
        ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
        : DateTime.now();
    return FeedPost(
      id: 'feed_${json['id'] ?? nextLocalId()}',
      kind: kind,
      time: time,
      html: kind == PostKind.drill ? '' : text,
      term: kind == PostKind.word ? (json['term'] ?? '') as String : null,
      drill: kind == PostKind.drill
          ? DrillPayload(pages: splitDrill(text))
          : null,
    );
  }

  static PostKind _kindFromString(String s) {
    switch (s) {
      case 'word':
        return PostKind.word;
      case 'drill':
        return PostKind.drill;
      case 'idiom':
        return PostKind.idiom;
      case 'collocation':
        return PostKind.collocation;
      case 'story':
        return PostKind.story;
      case 'tip':
        return PostKind.tip;
      default:
        return PostKind.text;
    }
  }

  static int _counter = 0;

  /// Monotonic, unique id for a locally-minted post (quiz/srs/lookup).
  static String nextLocalId() =>
      'p${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
}

/// Human label for a post kind, shown in the card header chip.
String postKindLabel(PostKind kind) {
  switch (kind) {
    case PostKind.word:
      return 'Word';
    case PostKind.drill:
      return 'Grammar drill';
    case PostKind.idiom:
      return 'Idiom';
    case PostKind.collocation:
      return 'Collocation';
    case PostKind.story:
      return 'Story';
    case PostKind.tip:
      return 'Grammar tip';
    case PostKind.quiz:
      return 'Quiz';
    case PostKind.srs:
      return 'Review';
    case PostKind.text:
      return 'Post';
  }
}

/// Splits a drill card into pages: a header, groups of up to four forms, and a
/// trailing tip — shown as a swipeable carousel.
List<String> splitDrill(String text) {
  final blocks = text
      .split('\n\n')
      .map((b) => b.trim())
      .where((b) => b.isNotEmpty)
      .toList();
  if (blocks.length <= 2) return [text.trim()];

  final header = blocks.first;
  String? footer;
  var bodyEnd = blocks.length;
  if (blocks.last.contains('💡')) {
    footer = blocks.last;
    bodyEnd = blocks.length - 1;
  }
  final forms = blocks.sublist(1, bodyEnd);
  if (forms.isEmpty) return [text.trim()];

  const perPage = 4;
  final pages = <String>[];
  for (var i = 0; i < forms.length; i += perPage) {
    final chunk = forms.sublist(i, (i + perPage).clamp(0, forms.length));
    final parts = <String>[header, ...chunk];
    if (footer != null) parts.add(footer);
    pages.add(parts.join('\n\n'));
  }
  return pages;
}
