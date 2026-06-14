class ReviewCard {
  final String term;
  final String meaning;
  final String pronunciation;
  final String persian;
  final String example;
  final String mnemonic;

  ReviewCard({required this.term, required this.meaning, this.pronunciation = '', this.persian = '', this.example = '', this.mnemonic = ''});

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? json['definition'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      persian: json['persian'] ?? '',
      example: json['example'] ?? '',
      mnemonic: json['mnemonic'] ?? '',
    );
  }
}

class LevelSuggestion {
  final bool suggest;
  final String currentLevel;
  final String currentLabel;
  final String direction;
  final int accuracy;
  final String targetLevel;
  final String targetLabel;
  final String message;

  LevelSuggestion({required this.suggest, required this.currentLevel, required this.currentLabel, this.direction = '', this.accuracy = 0, this.targetLevel = '', this.targetLabel = '', this.message = ''});

  factory LevelSuggestion.fromJson(Map<String, dynamic> json) {
    return LevelSuggestion(
      suggest: json['suggest'] ?? false,
      currentLevel: json['currentLevel'] ?? '',
      currentLabel: json['currentLabel'] ?? '',
      direction: json['direction'] ?? '',
      accuracy: json['accuracy'] ?? 0,
      targetLevel: json['targetLevel'] ?? '',
      targetLabel: json['targetLabel'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
