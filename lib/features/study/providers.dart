import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/deck.dart';
import '../../../core/models/grammar_lesson.dart';
import '../../../core/auth/auth_provider.dart';

final decksProvider = FutureProvider<List<DeckProgress>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.decks);
  final data = response.data;
  return (data['decks'] as List? ?? [])
      .map((d) => DeckProgress.fromJson(d))
      .toList();
});

final deckDetailProvider = FutureProvider.family<DeckDetail, String>((
  ref,
  deckId,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.decksDetail,
    queryParameters: {'deck': deckId},
  );
  return DeckDetail.fromJson(response.data);
});

final deckStudyProvider = FutureProvider.family<List<DeckStudyCard>, String>((
  ref,
  deckId,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.decksStudy,
    queryParameters: {'deck': deckId, 'limit': 30},
  );
  final data = response.data;
  return (data['items'] as List? ?? [])
      .map((c) => DeckStudyCard.fromJson(c))
      .toList();
});

final grammarLessonsProvider = FutureProvider<List<GrammarLesson>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.grammar);
  final data = response.data;
  return (data['lessons'] as List? ?? [])
      .map((l) => GrammarLesson.fromJson(l))
      .toList();
});

final grammarLessonProvider = FutureProvider.family<GrammarLesson, String>((
  ref,
  id,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.grammarLesson,
    queryParameters: {'id': id},
  );
  return GrammarLesson.fromJson(response.data);
});

final practiceProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  kind,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(
    ApiEndpoints.practice,
    queryParameters: {'kind': kind},
  );
  final data = response.data;
  if (data['available'] == false) return null;
  return data;
});
