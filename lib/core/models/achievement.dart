class Achievement {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String category;
  final bool unlocked;
  final int progress;
  final int target;

  Achievement({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.unlocked,
    required this.progress,
    required this.target,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      unlocked: json['unlocked'] ?? false,
      progress: json['progress'] ?? 0,
      target: json['target'] ?? 1,
    );
  }
}
