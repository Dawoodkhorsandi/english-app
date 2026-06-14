import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/models/grammar_lesson.dart';

class GrammarLessonScreen extends ConsumerWidget {
  final String lessonId;
  const GrammarLessonScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(grammarLessonProvider(lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Lesson')),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading lesson')),
        data: (lesson) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(lesson.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(lesson.pattern, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            Text(lesson.explanation),
            const SizedBox(height: 16),
            const Text('Examples', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...lesson.examples.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('- $e'),
            )),
            if (lesson.tip.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text('\u{1F4A1} ', style: TextStyle(fontSize: 18)),
                      Expanded(child: Text(lesson.tip)),
                    ],
                  ),
                ),
              ),
            ],
            if (lesson.practice.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Practice', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
    final isCorrect = _selected == widget.question.answer;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.question.q, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...widget.question.options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              Color? tileColor;
              if (_selected != null) {
                if (i == widget.question.answer) {
                  tileColor = Colors.green.withValues(alpha: 0.15);
                } else if (i == _selected) {
                  tileColor = Colors.red.withValues(alpha: 0.15);
                }
              }
              return ListTile(
                leading: Icon(
                  _selected == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: tileColor != null ? (i == widget.question.answer ? Colors.green : Colors.red) : null,
                ),
                title: Text(opt),
                tileColor: tileColor,
                dense: true,
                onTap: _selected == null ? () => setState(() => _selected = i) : null,
              );
            }),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  isCorrect ? '\u2705 Correct!' : '\u274C The correct answer is: ${widget.question.options[widget.question.answer]}',
                  style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
