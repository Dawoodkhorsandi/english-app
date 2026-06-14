class DictionaryEntry {
  final String word;
  final String pos;
  final String pronunciation;
  final String persian;
  final String romanization;
  final String definition;
  final String example;
  final String sense;
  final String tags;

  DictionaryEntry({
    required this.word,
    this.pos = '',
    this.pronunciation = '',
    this.persian = '',
    this.romanization = '',
    this.definition = '',
    this.example = '',
    this.sense = '',
    this.tags = '',
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word'] ?? '',
      pos: json['pos'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      persian: json['persian'] ?? '',
      romanization: json['romanization'] ?? '',
      definition: json['definition'] ?? '',
      example: json['example'] ?? '',
      sense: json['sense'] ?? '',
      tags: json['tags'] ?? '',
    );
  }
}
