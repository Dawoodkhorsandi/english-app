import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'grammar_lesson_screen.dart';
import '../../core/theme/app_spacing.dart';

class GrammarScreen extends ConsumerWidget {
  const GrammarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final lessonsAsync = ref.watch(grammarLessonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Grammar Lessons')),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading lessons')),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(child: Text('No lessons available.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: lessons.length,
            itemBuilder: (context, i) {
              final l = lessons[i];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${l.order}')),
                  title: Text(
                    l.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(l.level),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GrammarLessonScreen(lessonId: l.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
