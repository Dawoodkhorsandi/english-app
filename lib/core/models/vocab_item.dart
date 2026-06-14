class VocabItem {
  final String term;
  final String meaning;
  final String mastery;
  final bool bookmarked;

  VocabItem({
    required this.term,
    required this.meaning,
    required this.mastery,
    required this.bookmarked,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    return VocabItem(
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? '',
      mastery: json['mastery'] ?? 'new',
      bookmarked: json['bookmarked'] ?? false,
    );
  }
}

class VocabCard {
  final String term;
  final String meaning;
  final String text;

  VocabCard({required this.term, required this.meaning, required this.text});

  factory VocabCard.fromJson(Map<String, dynamic> json) {
    return VocabCard(
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? '',
      text: json['text'] ?? '',
    );
  }
}
