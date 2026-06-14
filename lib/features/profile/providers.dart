import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/stats.dart';
import '../../core/models/analytics.dart';
import '../../core/auth/auth_provider.dart';

final statsProvider = FutureProvider<Stats>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.stats);
  return Stats.fromJson(response.data);
});

final analyticsProvider = FutureProvider<Analytics>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.analytics);
  return Analytics.fromJson(response.data);
});
