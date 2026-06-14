import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/quiz.dart';
import '../../../core/auth/auth_provider.dart';

final quizProvider = FutureProvider<QuizQuestion>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.quizNext);
  return QuizQuestion.fromJson(response.data);
});
