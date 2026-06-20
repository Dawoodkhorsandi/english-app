/// Who sent a chat-feed message.
enum ChatSender { bot, user }

/// The kind of bubble to render. Mirrors the bot's content kinds plus the
/// app-only interactive/system bubbles.
enum ChatKind {
  word,
  drill,
  idiom,
  collocation,
  story,
  tip,
  quiz,
  srs,
  text,
  system,
  typing,
}

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

/// Payload for a grammar drill, split into Telegram-style pages the user can
/// flip through with ◀️ / ▶️.
class DrillPayload {
  final List<String> pages;
  int page;

  DrillPayload({required this.pages, this.page = 0});

  int get pageCount => pages.length;
}

/// A single message in the simulated Telegram chat feed.
class ChatMessage {
  final String id;
  final ChatSender sender;
  final ChatKind kind;
  final DateTime time;

  /// Telegram-HTML body for text/word/idiom/collocation/story/tip/system bubbles.
  final String html;

  /// The vocabulary term (word bubbles), used for bookmarking.
  final String? term;

  final QuizPayload? quiz;
  final SrsPayload? srs;
  final DrillPayload? drill;

  /// Local bookmark state for word bubbles (optimistic).
  bool bookmarked;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.kind,
    required this.time,
    this.html = '',
    this.term,
    this.quiz,
    this.srs,
    this.drill,
    this.bookmarked = false,
  });

  factory ChatMessage.system(String html) => ChatMessage(
    id: nextId(),
    sender: ChatSender.bot,
    kind: ChatKind.system,
    time: DateTime.now(),
    html: html,
  );

  factory ChatMessage.user(String text) => ChatMessage(
    id: nextId(),
    sender: ChatSender.user,
    kind: ChatKind.text,
    time: DateTime.now(),
    html: text,
  );

  factory ChatMessage.typing() => ChatMessage(
    id: nextId(),
    sender: ChatSender.bot,
    kind: ChatKind.typing,
    time: DateTime.now(),
  );

  static int _counter = 0;

  /// Monotonic, unique id for a new message.
  static String nextId() =>
      'm${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
}
