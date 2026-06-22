class AppSettings {
  final String level;
  final List<String> levels;
  final Map<String, String> levelLabels;
  final String name;
  final bool paused;
  final int interval;
  final Map<String, bool> toggles;
  final double desiredRetention; // FSRS target recall (0.70–0.97)
  final int streakFreezes; // banked streak-saver tokens
  final String examTarget; // '', 'ielts', or 'toefl'

  AppSettings({
    required this.level,
    required this.levels,
    required this.levelLabels,
    required this.name,
    required this.paused,
    required this.interval,
    required this.toggles,
    this.desiredRetention = 0.9,
    this.streakFreezes = 0,
    this.examTarget = '',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      level: json['level'] ?? 'intermediate',
      levels: List<String>.from(json['levels'] ?? []),
      levelLabels: Map<String, String>.from(json['levelLabels'] ?? {}),
      name: json['name'] ?? '',
      paused: json['paused'] ?? false,
      interval: json['interval'] ?? 60,
      toggles: Map<String, bool>.from(json['toggles'] ?? {}),
      desiredRetention: (json['desired_retention'] as num?)?.toDouble() ?? 0.9,
      streakFreezes: json['streak_freezes'] ?? 0,
      examTarget: json['exam_target'] ?? '',
    );
  }
}
