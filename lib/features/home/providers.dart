import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../profile/providers.dart';

/// Number of SRS cards currently due for review.
final reviewCountProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.reviewCount);
  return (response.data['count'] as int?) ?? 0;
});

/// Default daily word goal used until the user picks their own.
const int kDailyGoalTarget = 10;

/// Selectable daily word-goal values offered in the picker.
const List<int> kDailyGoalOptions = [5, 10, 15, 20, 25, 30, 40, 50];

/// The user's daily word goal, persisted locally (client-side; no backend).
final dailyGoalTargetProvider = NotifierProvider<DailyGoalTargetNotifier, int>(
  DailyGoalTargetNotifier.new,
);

class DailyGoalTargetNotifier extends Notifier<int> {
  static const _key = 'daily_goal_target';

  @override
  int build() {
    _load();
    return kDailyGoalTarget;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_key);
    if (v != null && v > 0) state = v;
  }

  Future<void> set(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}

/// Today's progress toward the daily goal, derived from the activity log
/// returned by [statsProvider]. Returns (done, target).
final dailyGoalProvider = Provider<({int done, int target})>((ref) {
  final target = ref.watch(dailyGoalTargetProvider);
  final stats = ref.watch(statsProvider).valueOrNull;
  if (stats == null) return (done: 0, target: target);
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final done = stats.activityCounts[todayKey] ?? 0;
  return (done: done, target: target);
});
