import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';

/// Number of SRS cards currently due for review.
final reviewCountProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.reviewCount);
  return (response.data['count'] as int?) ?? 0;
});
