import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/review_card.dart';
import '../../../core/auth/auth_provider.dart';

final reviewCardsProvider = FutureProvider<List<ReviewCard>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.reviewNext, queryParameters: {'limit': 30});
  final data = response.data;
  return (data['items'] as List? ?? []).map((c) => ReviewCard.fromJson(c)).toList();
});
