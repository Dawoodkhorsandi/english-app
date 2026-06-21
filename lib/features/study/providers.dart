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

/// IELTS/TOEFL exam-track status (#1): target deck + estimated band/score.
class ExamStatus {
  final String target; // '', 'ielts', 'toefl'
  final String label;
  final String deckId;
  final String deckName;
  final String estimate;
  final String scale; // 'band' or 'score'
  final int accuracy;
  final bool ready;
  final String detail;

  ExamStatus.fromJson(Map<String, dynamic> j)
    : target = j['target'] ?? '',
      label = j['label'] ?? '',
      deckId = j['deckId'] ?? '',
      deckName = j['deckName'] ?? '',
      estimate = j['estimate'] ?? '',
      scale = j['scale'] ?? '',
      accuracy = j['accuracy'] ?? 0,
      ready = j['ready'] ?? false,
      detail = j['detail'] ?? '';

  bool get active => target.isNotEmpty;
}

final examStatusProvider = FutureProvider<ExamStatus>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.exam);
  return ExamStatus.fromJson(Map<String, dynamic>.from(response.data));
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
