class DeckProgress {
  final String id;
  final String name;
  final String description;
  final int total;
  final int mastered;
  final int due;
  final int progressPct;

  DeckProgress({required this.id, required this.name, required this.description, required this.total, required this.mastered, required this.due, required this.progressPct});

  factory DeckProgress.fromJson(Map<String, dynamic> json) {
    return DeckProgress(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      total: json['total'] ?? 0,
      mastered: json['mastered'] ?? 0,
      due: json['due'] ?? 0,
      progressPct: json['progressPct'] ?? 0,
    );
  }
}

class DeckStudyCard {
  final String term;
  final String definition;
  final String example;
  final String persian;
  final String pronunciation;
  final String mnemonic;
  final int box;

  DeckStudyCard({required this.term, required this.definition, required this.example, this.persian = '', this.pronunciation = '', this.mnemonic = '', this.box = 1});

  factory DeckStudyCard.fromJson(Map<String, dynamic> json) {
    return DeckStudyCard(
      term: json['term'] ?? '',
      definition: json['definition'] ?? '',
      example: json['example'] ?? '',
      persian: json['persian'] ?? '',
      pronunciation: json['pronunciation'] ?? '',
      mnemonic: json['mnemonic'] ?? '',
      box: json['box'] ?? 1,
    );
  }
}

class DeckDetail {
  final String id;
  final String name;
  final String description;
  final int total;
  final int mastered;
  final int due;
  final int newCount;
  final int progressPct;
  final String nextReview;
  final List<BoxDistribution> boxes;

  DeckDetail({required this.id, required this.name, required this.description, required this.total, required this.mastered, required this.due, required this.newCount, required this.progressPct, required this.nextReview, required this.boxes});

  factory DeckDetail.fromJson(Map<String, dynamic> json) {
    return DeckDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      total: json['total'] ?? 0,
      mastered: json['mastered'] ?? 0,
      due: json['due'] ?? 0,
      newCount: json['new'] ?? 0,
      progressPct: json['progressPct'] ?? 0,
      nextReview: json['nextReview'] ?? '',
      boxes: (json['boxes'] as List? ?? []).map((b) => BoxDistribution.fromJson(b)).toList(),
    );
  }
}

class BoxDistribution {
  final int box;
  final String label;
  final int count;

  BoxDistribution({required this.box, required this.label, required this.count});

  factory BoxDistribution.fromJson(Map<String, dynamic> json) {
    return BoxDistribution(
      box: json['box'] ?? 0,
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
