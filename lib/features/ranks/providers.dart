import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/leaderboard.dart';
import '../../../core/auth/auth_provider.dart';

final leaderboardMetricProvider = StateProvider<String>((ref) => 'words');

final leaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  final client = ref.watch(apiClientProvider);
  final metric = ref.watch(leaderboardMetricProvider);
  final response = await client.get(ApiEndpoints.leaderboard, queryParameters: {'metric': metric});
  return LeaderboardResponse.fromJson(response.data);
});

final profileProvider = FutureProvider.family<ProfileResponse, String>((ref, userId) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.profile, queryParameters: {'id': userId});
  return ProfileResponse.fromJson(response.data);
});