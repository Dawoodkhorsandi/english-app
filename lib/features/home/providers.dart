import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../profile/providers.dart';

/// Number of SRS cards currently due for review.
final reviewCountProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.reviewCount);
  return (response.data['count'] as int?) ?? 0;
});

/// Daily word goal (client-side, fixed target).
const int kDailyGoalTarget = 10;

/// Today's progress toward the daily goal, derived from the activity log
/// returned by [statsProvider]. Returns (done, target).
final dailyGoalProvider = Provider<({int done, int target})>((ref) {
  final stats = ref.watch(statsProvider).valueOrNull;
  if (stats == null) return (done: 0, target: kDailyGoalTarget);
  final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final done = stats.activityCounts[todayKey] ?? 0;
  return (done: done, target: kDailyGoalTarget);
});
