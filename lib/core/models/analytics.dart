class Analytics {
  final List<AnalyticsEntry> wordBreakdown;
  final List<QuizTrend> quizAccuracyTrend;
  final List<HourlyActivity> activityByHour;
  final List<WeeklyVelocity> weeklyVelocity;
  final List<AnalyticsEntry> contentDiversity;

  Analytics({required this.wordBreakdown, required this.quizAccuracyTrend, required this.activityByHour, required this.weeklyVelocity, required this.contentDiversity});

  factory Analytics.fromJson(Map<String, dynamic> json) {
    return Analytics(
      wordBreakdown: (json['word_breakdown'] as List? ?? []).map((e) => AnalyticsEntry.fromJson(e)).toList(),
      quizAccuracyTrend: (json['quiz_accuracy_trend'] as List? ?? []).map((e) => QuizTrend.fromJson(e)).toList(),
      activityByHour: (json['activity_by_hour'] as List? ?? []).map((e) => HourlyActivity.fromJson(e)).toList(),
      weeklyVelocity: (json['weekly_velocity'] as List? ?? []).map((e) => WeeklyVelocity.fromJson(e)).toList(),
      contentDiversity: (json['content_diversity'] as List? ?? []).map((e) => AnalyticsEntry.fromJson(e)).toList(),
    );
  }
}

class AnalyticsEntry {
  final String label;
  final int count;

  AnalyticsEntry({required this.label, required this.count});

  factory AnalyticsEntry.fromJson(Map<String, dynamic> json) {
    return AnalyticsEntry(label: json['label'] ?? '', count: json['count'] ?? 0);
  }
}

class QuizTrend {
  final String date;
  final int correct;
  final int total;
  final int pct;

  QuizTrend({required this.date, required this.correct, required this.total, required this.pct});

  factory QuizTrend.fromJson(Map<String, dynamic> json) {
    return QuizTrend(date: json['date'] ?? '', correct: json['correct'] ?? 0, total: json['total'] ?? 0, pct: json['pct'] ?? 0);
  }
}

class HourlyActivity {
  final int hour;
  final int count;

  HourlyActivity({required this.hour, required this.count});

  factory HourlyActivity.fromJson(Map<String, dynamic> json) {
    return HourlyActivity(hour: json['hour'] ?? 0, count: json['count'] ?? 0);
  }
}

class WeeklyVelocity {
  final String week;
  final int count;

  WeeklyVelocity({required this.week, required this.count});

  factory WeeklyVelocity.fromJson(Map<String, dynamic> json) {
    return WeeklyVelocity(week: json['week'] ?? '', count: json['count'] ?? 0);
  }
}
