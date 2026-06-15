import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/vocab_item.dart';
import '../../core/models/content_item.dart';
import '../../core/models/quiz.dart';
import '../../core/auth/auth_provider.dart';

final vocabProvider = FutureProvider.family<VocabResponse, VocabParams>((
  ref,
  params,
) async {
  final client = ref.watch(apiClientProvider);
  final query = <String, dynamic>{
    'offset': params.offset,
    'limit': params.limit,
  };
  if (params.bookmarks) query['bookmarks'] = '1';
  if (params.q.isNotEmpty) query['q'] = params.q;
  final response = await client.get(ApiEndpoints.vocab, queryParameters: query);
  final data = response.data;
  return VocabResponse(
    items: (data['items'] as List? ?? [])
        .map((i) => VocabItem.fromJson(i))
        .toList(),
    total: data['total'] ?? 0,
  );
});

/// Fetches the full detail card for a single word (text, meaning).
final vocabCardProvider = FutureProvider.family<VocabCard, String>((
  ref,
  term,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.vocabCard,
    queryParameters: {'term': term},
  );
  return VocabCard.fromJson(response.data);
});

class VocabParams {
  final int offset;
  final int limit;
  final bool bookmarks;
  final String q;
  VocabParams({
    this.offset = 0,
    this.limit = 20,
    this.bookmarks = false,
    this.q = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabParams &&
          other.offset == offset &&
          other.limit == limit &&
          other.bookmarks == bookmarks &&
          other.q == q;

  @override
  int get hashCode => Object.hash(offset, limit, bookmarks, q);
}

class VocabResponse {
  final List<VocabItem> items;
  final int total;
  VocabResponse({required this.items, required this.total});
}

final contentProvider = FutureProvider.family<List<ContentItem>, String>((
  ref,
  kind,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.content,
    queryParameters: {'kind': kind, 'offset': 0, 'limit': 100},
  );
  final data = response.data;
  return (data['items'] as List? ?? [])
      .map((i) => ContentItem.fromJson(i))
      .toList();
});

final quizHistoryProvider = FutureProvider<List<QuizHistoryItem>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.quizzes,
    queryParameters: {'offset': 0, 'limit': 100},
  );
  final data = response.data;
  return (data['items'] as List? ?? [])
      .map((i) => QuizHistoryItem.fromJson(i))
      .toList();
});

final dictionaryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      query,
    ) async {
      if (query.isEmpty) return [];
      final client = ref.watch(apiClientProvider);
      final response = await client.get(
        ApiEndpoints.dictionary,
        queryParameters: {'q': query},
      );
      final data = response.data;
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    });
