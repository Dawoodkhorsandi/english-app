import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/stats.dart';
import 'models/chat_message.dart';

/// Drives the simulated Telegram chat feed: it holds the message list, ticks on
/// the user's broadcast interval to grow the conversation live, and exposes the
/// interactive actions (reply-keyboard taps, quiz/SRS answers, word lookups).
///
/// The provider is app-scoped (not autoDispose), so the conversation and its
/// ticker survive tab switches.
final feedControllerProvider =
    NotifierProvider<FeedController, List<ChatMessage>>(FeedController.new);

const _welcomeHtml =
    '👋 <b>Welcome to English Muscle Memory Bot!</b>\n\n'
    'I\'ll drip grammar drills and vocabulary on your schedule — and you can pull '
    'content any time with the buttons below.\n\n'
    '💬 <b>Tip:</b> send me <b>any word</b> (English or Persian) and I\'ll explain '
    'it like a vocabulary card!';

class FeedController extends Notifier<List<ChatMessage>> {
  Timer? _timer;
  int _interval = 60; // minutes; overwritten from /api/settings
  int? _lastSlot;
  bool _bootstrapped = false;

  @override
  List<ChatMessage> build() {
    ref.onDispose(() => _timer?.cancel());
    // Kick off async setup once; the welcome bubble shows immediately.
    if (!_bootstrapped) {
      _bootstrapped = true;
      Future.microtask(_bootstrap);
    }
    return [ChatMessage.system(_welcomeHtml)];
  }

  ApiClient get _client => ref.read(apiClientProvider);

  Future<void> _bootstrap() async {
    try {
      final r = await _client.get(ApiEndpoints.settings);
      final iv = r.data['interval'];
      if (iv is int && iv > 0) _interval = iv;
    } catch (_) {
      // Keep the default interval if settings can't be read.
    }
    _lastSlot = _currentSlot();
    // Deliver the current slot's message once so the chat isn't empty.
    await _deliverPooled(null);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  int _currentSlot() {
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    return mins ~/ (_interval <= 0 ? 60 : _interval);
  }

  void _tick() {
    final slot = _currentSlot();
    if (_lastSlot != null && slot != _lastSlot) {
      _lastSlot = slot;
      _deliverPooled(null);
    }
  }

  // ---- public actions -----------------------------------------------------

  /// Reply-keyboard taps. [kind] is one of word/drill/idiom/collocation/story/
  /// tip (pooled content), or 'quiz'/'stats' (special handlers).
  Future<void> requestKind(String kind) async {
    switch (kind) {
      case 'quiz':
        await _deliverQuiz();
      case 'review':
        await _deliverReview();
      case 'stats':
        await _deliverStats();
      default:
        await _deliverPooled(kind);
    }
  }

  /// Free-text word lookup from the chat input.
  Future<void> lookup(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    _append(ChatMessage.user(trimmed));
    final typing = _showTyping();
    try {
      final r = await _client.get(
        ApiEndpoints.lookup,
        queryParameters: {'term': trimmed},
      );
      _removeTyping(typing);
      final data = r.data as Map;
      if (data['available'] == true) {
        _append(
          ChatMessage(
            id: ChatMessage.nextId(),
            sender: ChatSender.bot,
            kind: ChatKind.word,
            time: DateTime.now(),
            html: (data['text'] ?? '') as String,
            term: (data['term'] ?? '') as String,
          ),
        );
      } else {
        _append(
          ChatMessage.system(
            (data['message'] ?? 'I couldn\'t look that up — try a single word.')
                as String,
          ),
        );
      }
    } catch (_) {
      _removeTyping(typing);
      _append(
        ChatMessage.system(
          '❌ Sorry, I couldn\'t look that up right now. Please try again.',
        ),
      );
    }
  }

  Future<void> answerQuiz(String messageId, int option) async {
    final msg = _byId(messageId);
    final quiz = msg?.quiz;
    if (msg == null || quiz == null || quiz.isAnswered) return;
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
    } catch (_) {
      // The selection still shows locally; result is best-effort recorded.
    }
  }

  Future<void> answerSrs(String messageId, bool known) async {
    final msg = _byId(messageId);
    final srs = msg?.srs;
    if (msg == null || srs == null || srs.isAnswered) return;
    srs.known = known;
    _emit();
    try {
      await _client.post(
        ApiEndpoints.reviewAnswer,
        data: {'term': srs.term, 'known': known},
      );
    } catch (_) {}
  }

  Future<void> toggleBookmark(String messageId) async {
    final msg = _byId(messageId);
    if (msg == null || msg.term == null || msg.term!.isEmpty) return;
    msg.bookmarked = !msg.bookmarked;
    _emit();
    try {
      await _client.post(
        ApiEndpoints.bookmark,
        data: {'term': msg.term, 'on': msg.bookmarked},
      );
    } catch (_) {
      msg.bookmarked = !msg.bookmarked;
      _emit();
    }
  }

  void setDrillPage(String messageId, int page) {
    final drill = _byId(messageId)?.drill;
    if (drill == null) return;
    drill.page = page.clamp(0, drill.pageCount - 1);
    _emit();
  }

  // ---- delivery helpers ---------------------------------------------------

  Future<void> _deliverPooled(String? kind) async {
    final typing = _showTyping();
    try {
      final r = await _client.get(
        ApiEndpoints.feedNext,
        queryParameters: kind == null ? null : {'kind': kind},
      );
      _removeTyping(typing);
      final data = r.data as Map;
      if (data['available'] != true) {
        _append(
          ChatMessage.system(
            '📭 Nothing in the pool yet for that — try again soon!',
          ),
        );
        return;
      }
      final serverKind = (data['kind'] ?? 'word') as String;
      final text = (data['text'] ?? '') as String;
      final term = (data['term'] ?? '') as String;
      _append(_pooledMessage(serverKind, text, term));
    } catch (_) {
      _removeTyping(typing);
      _append(
        ChatMessage.system(
          '❌ Couldn\'t fetch that right now. Please try again.',
        ),
      );
    }
  }

  ChatMessage _pooledMessage(String serverKind, String text, String term) {
    final id = ChatMessage.nextId();
    final now = DateTime.now();
    switch (serverKind) {
      case 'drill':
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.drill,
          time: now,
          drill: DrillPayload(pages: _splitDrill(text)),
        );
      case 'word':
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.word,
          time: now,
          html: text,
          term: term,
        );
      case 'idiom':
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.idiom,
          time: now,
          html: text,
        );
      case 'collocation':
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.collocation,
          time: now,
          html: text,
        );
      case 'story':
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.story,
          time: now,
          html: text,
        );
      case 'tip':
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.tip,
          time: now,
          html: text,
        );
      default:
        return ChatMessage(
          id: id,
          sender: ChatSender.bot,
          kind: ChatKind.text,
          time: now,
          html: text,
        );
    }
  }

  Future<void> _deliverQuiz() async {
    final typing = _showTyping();
    try {
      final r = await _client.get(ApiEndpoints.quizNext);
      _removeTyping(typing);
      final data = r.data as Map;
      if (data['available'] != true) {
        _append(
          ChatMessage.system(
            '🧩 No quiz yet — learn a few words first and I\'ll start testing you!',
          ),
        );
        return;
      }
      _append(
        ChatMessage(
          id: ChatMessage.nextId(),
          sender: ChatSender.bot,
          kind: ChatKind.quiz,
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
    } catch (_) {
      _removeTyping(typing);
      _append(
        ChatMessage.system(
          '❌ Couldn\'t load a quiz right now. Please try again.',
        ),
      );
    }
  }

  Future<void> _deliverReview() async {
    final typing = _showTyping();
    try {
      final r = await _client.get(
        ApiEndpoints.reviewNext,
        queryParameters: {'limit': 1},
      );
      _removeTyping(typing);
      final items = (r.data['items'] as List? ?? const []);
      if (items.isEmpty) {
        _append(
          ChatMessage.system(
            '✅ All caught up — no words due for review right now!',
          ),
        );
        return;
      }
      final c = Map<String, dynamic>.from(items.first as Map);
      _append(
        ChatMessage(
          id: ChatMessage.nextId(),
          sender: ChatSender.bot,
          kind: ChatKind.srs,
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
    } catch (_) {
      _removeTyping(typing);
      _append(
        ChatMessage.system(
          '❌ Couldn\'t load a review card right now. Please try again.',
        ),
      );
    }
  }

  Future<void> _deliverStats() async {
    final typing = _showTyping();
    try {
      final r = await _client.get(ApiEndpoints.stats);
      _removeTyping(typing);
      final s = Stats.fromJson(Map<String, dynamic>.from(r.data as Map));
      _append(
        ChatMessage.system(
          '📊 <b>Your Progress</b>\n\n'
          '📘 Vocabulary words: <b>${s.words}</b>  (<b>${s.mastered}</b> mastered)\n'
          '🎯 Grammar drills: <b>${s.verbs}</b>\n'
          '⚡ Streak: <b>${s.currentStreak} days</b> 🔥  (best ${s.longestStreak})\n'
          '🧩 Quiz accuracy: <b>${s.quizPct}%</b> (${s.quizCorrect}/${s.quizAnswered})\n'
          '🎚️ Level: <b>${s.level}</b>\n\n'
          'Keep going — say each word aloud to lock it in! 💪',
        ),
      );
    } catch (_) {
      _removeTyping(typing);
      _append(
        ChatMessage.system(
          '❌ Couldn\'t load your stats right now. Please try again.',
        ),
      );
    }
  }

  // ---- list plumbing ------------------------------------------------------

  ChatMessage? _byId(String id) {
    for (final m in state) {
      if (m.id == id) return m;
    }
    return null;
  }

  void _append(ChatMessage m) => state = [...state, m];

  void _emit() => state = [...state];

  String _showTyping() {
    final t = ChatMessage.typing();
    _append(t);
    return t.id;
  }

  void _removeTyping(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

/// Splits a Telegram drill card into pages: a header, groups of up to four forms,
/// and a trailing tip — flippable with ◀️/▶️ like the real bot.
List<String> _splitDrill(String text) {
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
