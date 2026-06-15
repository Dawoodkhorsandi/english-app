import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/grammar_lesson.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class GrammarLessonScreen extends ConsumerWidget {
  final String lessonId;
  const GrammarLessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final lessonAsync = ref.watch(grammarLessonProvider(lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Lesson')),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading lesson')),
        data: (lesson) => ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            Text(
              lesson.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.borderLg,
              ),
              child: Text(
                lesson.pattern,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(lesson.explanation),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Examples',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...lesson.examples.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('- $e'),
              ),
            ),
            if (lesson.tip.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Text('\u{1F4A1} ', style: textTheme.titleMedium),
                      Expanded(child: Text(lesson.tip)),
                    ],
                  ),
                ),
              ),
            ],
            if (lesson.practice.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'Practice',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...lesson.practice.map((p) => _PracticeQuestion(question: p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeQuestion extends StatefulWidget {
  final PracticeQuestion question;
  const _PracticeQuestion({required this.question});

  @override
  State<_PracticeQuestion> createState() => _PracticeQuestionState();
}

class _PracticeQuestionState extends State<_PracticeQuestion> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCorrect = _selected == widget.question.answer;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.q,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...widget.question.options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              Color? tileColor;
              if (_selected != null) {
                if (i == widget.question.answer) {
                  tileColor = AppColors.successContainer;
                } else if (i == _selected) {
                  tileColor = AppColors.dangerContainer;
                }
              }
              return ListTile(
                leading: Icon(
                  _selected == i
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: tileColor != null
                      ? (i == widget.question.answer
                            ? AppColors.success
                            : AppColors.danger)
                      : null,
                ),
                title: Text(opt),
                tileColor: tileColor,
                dense: true,
                onTap: _selected == null
                    ? () => setState(() => _selected = i)
                    : null,
              );
            }),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  isCorrect
                      ? '\u2705 Correct!'
                      : '\u274C The correct answer is: ${widget.question.options[widget.question.answer]}',
                  style: textTheme.titleSmall?.copyWith(
                    color: isCorrect ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
