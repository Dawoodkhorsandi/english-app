import 'achievement.dart';

class Stats {
  final int currentStreak;
  final int longestStreak;
  final int words;
  final int mastered;
  final int verbs;
  final int quizAnswered;
  final int quizCorrect;
  final int quizPct;
  final int idioms;
  final int collocations;
  final int stories;
  final int tips;
  final int activeDays;
  final List<String> activityDays;
  final Map<String, int> activityCounts;
  final String level;
  final bool paused;
  final String memberSince;
  final List<Achievement> achievements;
  final int achUnlocked;
  final int achTotal;

  Stats({
    required this.currentStreak,
    required this.longestStreak,
    required this.words,
    required this.mastered,
    required this.verbs,
    required this.quizAnswered,
    required this.quizCorrect,
    required this.quizPct,
    required this.idioms,
    required this.collocations,
    required this.stories,
    required this.tips,
    required this.activeDays,
    required this.activityDays,
    required this.activityCounts,
    required this.level,
    required this.paused,
    required this.memberSince,
    required this.achievements,
    required this.achUnlocked,
    required this.achTotal,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      words: json['words'] ?? 0,
      mastered: json['mastered'] ?? 0,
      verbs: json['verbs'] ?? 0,
      quizAnswered: json['quiz_answered'] ?? 0,
      quizCorrect: json['quiz_correct'] ?? 0,
      quizPct: json['quiz_pct'] ?? 0,
      idioms: json['idioms'] ?? 0,
      collocations: json['collocations'] ?? 0,
      stories: json['stories'] ?? 0,
      tips: json['tips'] ?? 0,
      activeDays: json['active_days'] ?? 0,
      activityDays: List<String>.from(json['activity_days'] ?? []),
      activityCounts: Map<String, int>.from(json['activity_counts'] ?? {}),
      level: json['level'] ?? 'intermediate',
      paused: json['paused'] ?? false,
      memberSince: json['member_since'] ?? '',
      achievements: (json['achievements'] as List? ?? [])
          .map((a) => Achievement.fromJson(a))
          .toList(),
      achUnlocked: json['ach_unlocked'] ?? 0,
      achTotal: json['ach_total'] ?? 0,
    );
  }
}
