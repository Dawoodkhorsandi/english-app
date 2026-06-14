class QuizQuestion {
  final bool available;
  final String prompt;
  final List<String> options;
  final String word;
  final int correct;
  final int exp;
  final String token;

  QuizQuestion({required this.available, this.prompt = '', this.options = const [], this.word = '', this.correct = 0, this.exp = 0, this.token = ''});

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      available: json['available'] ?? false,
      prompt: json['prompt'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      word: json['word'] ?? '',
      correct: json['correct'] ?? 0,
      exp: json['exp'] ?? 0,
      token: json['token'] ?? '',
    );
  }
}

class QuizHistoryItem {
  final String word;
  final bool correct;
  final String answeredAt;

  QuizHistoryItem({required this.word, required this.correct, required this.answeredAt});

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      word: json['word'] ?? '',
      correct: json['correct'] ?? false,
      answeredAt: json['answered_at'] ?? '',
    );
  }
}
