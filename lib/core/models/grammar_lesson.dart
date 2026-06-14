class GrammarLesson {
  final String id;
  final int order;
  final String level;
  final String title;
  final String pattern;
  final String explanation;
  final List<String> examples;
  final String tip;
  final List<PracticeQuestion> practice;

  GrammarLesson({required this.id, required this.order, required this.level, required this.title, this.pattern = '', this.explanation = '', this.examples = const [], this.tip = '', this.practice = const []});

  factory GrammarLesson.fromJson(Map<String, dynamic> json) {
    return GrammarLesson(
      id: json['id'] ?? '',
      order: json['order'] ?? 0,
      level: json['level'] ?? '',
      title: json['title'] ?? '',
      pattern: json['pattern'] ?? '',
      explanation: json['explanation'] ?? '',
      examples: List<String>.from(json['examples'] ?? []),
      tip: json['tip'] ?? '',
      practice: (json['practice'] as List? ?? []).map((p) => PracticeQuestion.fromJson(p)).toList(),
    );
  }
}

class PracticeQuestion {
  final String q;
  final List<String> options;
  final int answer;

  PracticeQuestion({required this.q, required this.options, required this.answer});

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    return PracticeQuestion(
      q: json['q'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? 0,
    );
  }
}
