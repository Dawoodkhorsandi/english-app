import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final quizAsync = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🧩 Quiz')),
      body: quizAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
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
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.prompt,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ...quiz.options.asMap().entries.map((entry) {
                          final i = entry.key;
                          final opt = entry.value;
                          Color? color;
                          if (_result != null) {
                            if (i == quiz.correct) {
                              color = AppColors.successContainer;
                            } else if (i == _selected) {
                              color = AppColors.dangerContainer;
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Material(
                              color: color ?? colorScheme.surface,
                              borderRadius: AppRadius.borderLg,
                              child: InkWell(
                                borderRadius: AppRadius.borderLg,
                                onTap: _result != null
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _selected = i);
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    AppSpacing.cardPadding,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: AppRadius.borderLg,
                                    border: Border.all(
                                      color: _selected == i
                                          ? colorScheme.primary
                                          : colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    opt,
                                    style: textTheme.bodyLarge?.copyWith(
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Center(
                      child: Text(
                        _result! ? '✅ Correct!' : '❌ Wrong!',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _result!
                              ? AppColors.success
                              : AppColors.danger,
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
