import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_detail_screen.dart';
import 'content_list_screen.dart';
import 'grammar_lesson_screen.dart';
import '../profile/providers.dart';
import '../../core/models/grammar_lesson.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/pill_badge.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/segmented_tabs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Learn',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedTabs(
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              tabs: const [
                SegmentedTab(label: 'Decks', icon: Icons.layers_outlined),
                SegmentedTab(label: 'Grammar', icon: Icons.school_outlined),
                SegmentedTab(label: 'Content', icon: Icons.menu_book_outlined),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: switch (_tab) {
                0 => const _DecksTab(),
                1 => const _GrammarTab(),
                _ => const _ContentTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decks tab
// ---------------------------------------------------------------------------
class _DecksTab extends ConsumerWidget {
  const _DecksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(decksProvider),
      child: decksAsync.when(
        loading: () => const LoadingSkeleton(lines: 5),
        error: (e, s) => ErrorState(
          message: 'Could not load decks',
          onRetry: () => ref.invalidate(decksProvider),
        ),
        data: (decks) {
          if (decks.isEmpty) {
            return const EmptyState(
              icon: Icons.library_books,
              title: 'No decks yet',
              subtitle: 'Decks appear as you learn new words.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: decks.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _DeckTile(deck: decks[i], index: i),
          );
        },
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  final dynamic deck;
  final int index;
  const _DeckTile({required this.deck, required this.index});

  static const _palette = [
    (AppColors.accentBlue, Icons.menu_book_outlined),
    (AppColors.accentPurple, Icons.school_outlined),
    (AppColors.accentTeal, Icons.link),
    (AppColors.accentOrange, Icons.work_outline),
    (AppColors.danger, Icons.account_balance_outlined),
    (AppColors.accentBlue, Icons.edit_note_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (deck.progressPct as int).clamp(0, 100) / 100.0;
    final (accent, icon) = _palette[index % _palette.length];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                DeckDetailScreen(deckId: deck.id, deckName: deck.name),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ProgressRing(
                progress: progress,
                size: 44,
                strokeWidth: 4,
                color: accent,
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${deck.mastered}/${deck.total} mastered',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (deck.due > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      PillBadge(
                        text: '${deck.due} due',
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grammar tab
// ---------------------------------------------------------------------------
class _GrammarTab extends ConsumerWidget {
  const _GrammarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(grammarLessonsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(grammarLessonsProvider),
      child: lessonsAsync.when(
        loading: () => const LoadingSkeleton(lines: 5),
        error: (e, s) => ErrorState(
          message: 'Could not load lessons',
          onRetry: () => ref.invalidate(grammarLessonsProvider),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const EmptyState(
              icon: Icons.auto_fix_high,
              title: 'No lessons yet',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: lessons.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _GrammarTile(lesson: lessons[i]),
          );
        },
      ),
    );
  }
}

class _GrammarTile extends StatelessWidget {
  final GrammarLesson lesson;
  const _GrammarTile({required this.lesson});

  static (Color, Color) _levelColors(String level) {
    final l = level.toLowerCase();
    if (l.contains('upper')) {
      return (AppColors.accentPurple, AppColors.accentPurpleBg);
    }
    if (l.contains('inter')) {
      return (AppColors.accentBlue, AppColors.accentBlueBg);
    }
    if (l.contains('begin')) {
      return (AppColors.success, AppColors.successContainer);
    }
    return (AppColors.accentOrange, AppColors.accentOrangeBg);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final (levelFg, levelBg) = _levelColors(lesson.level);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GrammarLessonScreen(lessonId: lesson.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${lesson.order}',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: levelBg,
                            borderRadius: AppRadius.borderFull,
                          ),
                          child: Text(
                            lesson.level,
                            style: textTheme.labelSmall?.copyWith(
                              color: levelFg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (lesson.pattern.isNotEmpty)
                          Text(
                            lesson.pattern,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content tab
// ---------------------------------------------------------------------------
class _ContentTab extends ConsumerWidget {
  const _ContentTab();

  static const _types = [
    (kind: 'idiom', label: 'Idioms', emoji: '\u{1F4AC}'),
    (kind: 'collocation', label: 'Collocations', emoji: '\u{1F517}'),
    (kind: 'story', label: 'Stories', emoji: '\u{1F4D6}'),
    (kind: 'tip', label: 'Tips', emoji: '\u{1F4A1}'),
  ];

  int _countFor(dynamic stats, String kind) {
    if (stats == null) return 0;
    return switch (kind) {
      'idiom' => stats.idioms as int,
      'collocation' => stats.collocations as int,
      'story' => stats.stories as int,
      _ => stats.tips as int,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final stats = ref.watch(statsProvider).valueOrNull;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.1,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: _types.map((ct) {
        final count = _countFor(stats, ct.kind);
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ContentListScreen(kind: ct.kind, title: ct.label),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ct.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ct.label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '$count items',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
