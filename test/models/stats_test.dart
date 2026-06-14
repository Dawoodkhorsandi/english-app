import 'package:flutter_test/flutter_test.dart';

import 'package:english_app/core/models/stats.dart';

void main() {
  group('Stats', () {
    test('parses from JSON correctly', () {
      final json = {
        'current_streak': 5,
        'longest_streak': 12,
        'words': 200,
        'mastered': 50,
        'verbs': 30,
        'quiz_answered': 100,
        'quiz_correct': 80,
        'quiz_pct': 80,
        'idioms': 15,
        'collocations': 10,
        'stories': 8,
        'tips': 12,
        'active_days': 25,
        'activity_days': ['2026-06-10', '2026-06-11'],
        'activity_counts': {'2026-06-10': 5, '2026-06-11': 3},
        'level': 'advanced',
        'paused': false,
        'member_since': '2026-01-01',
        'achievements': [],
        'ach_unlocked': 2,
        'ach_total': 10,
      };

      final stats = Stats.fromJson(json);

      expect(stats.currentStreak, 5);
      expect(stats.longestStreak, 12);
      expect(stats.words, 200);
      expect(stats.mastered, 50);
      expect(stats.verbs, 30);
      expect(stats.quizAnswered, 100);
      expect(stats.quizCorrect, 80);
      expect(stats.quizPct, 80);
      expect(stats.idioms, 15);
      expect(stats.collocations, 10);
      expect(stats.stories, 8);
      expect(stats.tips, 12);
      expect(stats.activeDays, 25);
      expect(stats.activityDays, ['2026-06-10', '2026-06-11']);
      expect(stats.activityCounts, {'2026-06-10': 5, '2026-06-11': 3});
      expect(stats.level, 'advanced');
      expect(stats.paused, false);
      expect(stats.memberSince, '2026-01-01');
      expect(stats.achUnlocked, 2);
      expect(stats.achTotal, 10);
    });

    test('handles missing fields with defaults', () {
      final stats = Stats.fromJson({});

      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.words, 0);
      expect(stats.mastered, 0);
      expect(stats.level, 'intermediate');
      expect(stats.paused, false);
      expect(stats.memberSince, '');
      expect(stats.activityDays, isEmpty);
      expect(stats.activityCounts, isEmpty);
      expect(stats.achievements, isEmpty);
    });

    test('parses achievements list', () {
      final json = {
        'achievements': [
          {
            'id': 'a1',
            'name': 'First Word',
            'icon': '📖',
            'description': 'Learn your first word',
            'category': 'learning',
            'unlocked': true,
            'progress': 1,
            'target': 1,
          },
          {
            'id': 'a2',
            'name': 'Streak 7',
            'icon': '🔥',
            'description': '7 day streak',
            'category': 'streak',
            'unlocked': false,
            'progress': 3,
            'target': 7,
          },
        ],
      };

      final stats = Stats.fromJson(json);

      expect(stats.achievements.length, 2);
      expect(stats.achievements[0].id, 'a1');
      expect(stats.achievements[0].unlocked, isTrue);
      expect(stats.achievements[1].id, 'a2');
      expect(stats.achievements[1].target, 7);
    });

    test('parses activity counts', () {
      final json = {
        'activity_counts': {'2026-06-01': 10, '2026-06-02': 0, '2026-06-03': 5},
      };

      final stats = Stats.fromJson(json);

      expect(stats.activityCounts.length, 3);
      expect(stats.activityCounts['2026-06-01'], 10);
      expect(stats.activityCounts['2026-06-02'], 0);
    });
  });
}
