class ContentItem {
  final String term;
  final String meaning;
  final String text;
  final String sentAt;

  ContentItem({required this.term, required this.meaning, required this.text, required this.sentAt});

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? '',
      text: json['text'] ?? '',
      sentAt: json['sent_at'] ?? '',
    );
  }
}
