import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int? _selected;
  bool? _result;

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🧩 Quiz')),
      body: quizAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingSkeleton(lines: 5),
        ),
        error: (e, s) => ErrorState(
          message: 'Could not load quiz',
          onRetry: () => ref.invalidate(quizProvider),
        ),
        data: (quiz) {
          if (!quiz.available) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No quiz available right now.',
              subtitle: 'Try again later.',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.prompt,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...quiz.options.asMap().entries.map((entry) {
                          final i = entry.key;
                          final opt = entry.value;
                          Color? color;
                          if (_result != null) {
                            if (i == quiz.correct) {
                              color = Colors.green.withValues(alpha: 0.15);
                            } else if (i == _selected) {
                              color = Colors.red.withValues(alpha: 0.15);
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color:
                                  color ??
                                  Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _result != null
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _selected = i);
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selected == i
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      fontWeight: _selected == i
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_result != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Text(
                        _result! ? '✅ Correct!' : '❌ Wrong!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _result! ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected == null
                        ? null
                        : _result != null
                        ? () {
                            setState(() {
                              _selected = null;
                              _result = null;
                            });
                            ref.invalidate(quizProvider);
                          }
                        : _submitAnswer,
                    child: Text(_result != null ? 'Next Question' : 'Submit'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitAnswer() async {
    final quiz = ref.read(quizProvider).value;
    if (quiz == null || _selected == null) return;
    final client = ref.read(apiClientProvider);
    try {
      final response = await client.post(
        ApiEndpoints.quizAnswer,
        data: {
          'word': quiz.word,
          'correct': quiz.correct,
          'exp': quiz.exp,
          'token': quiz.token,
          'answer': _selected!,
        },
      );
      final correct = response.data['correct'] ?? false;
      HapticFeedback.mediumImpact();
      setState(() => _result = correct);
    } catch (e) {
      HapticFeedback.mediumImpact();
      setState(() => _result = false);
    }
  }
}
