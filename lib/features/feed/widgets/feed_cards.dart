import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/rich_html.dart';
import '../models/feed_post.dart';
import '../providers.dart';

/// Renders one feed post as a full-width social-style card.
class FeedCard extends ConsumerWidget {
  final FeedPost post;
  const FeedCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(post: post),
            const SizedBox(height: AppSpacing.md),
            _Body(post: post),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: AppSpacing.lg),
            _ActionBar(post: post),
            if (post.comments.isNotEmpty) _CommentsPreview(post: post),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FeedPost post;
  const _Header({required this.post});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _kindEmoji(post.kind),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'English Muscle Memory',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${postKindLabel(post.kind)} · ${_timeAgo(post.time)}',
                style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        _KindChip(kind: post.kind),
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  final PostKind kind;
  const _KindChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: AppRadius.borderFull,
      ),
      child: Text(
        postKindLabel(kind),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final FeedPost post;
  const _Body({required this.post});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
    );
    switch (post.kind) {
      case PostKind.quiz:
        return _QuizBody(post: post);
      case PostKind.srs:
        return _SrsBody(post: post);
      case PostKind.drill:
        return _DrillCarousel(post: post);
      default:
        return RichHtml(post.html, style: base);
    }
  }
}

// ---------------------------------------------------------------------------
// Action bar (Like / Comment / Save / Share)
// ---------------------------------------------------------------------------

class _ActionBar extends ConsumerWidget {
  final FeedPost post;
  const _ActionBar({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(feedControllerProvider.notifier);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: post.liked ? Icons.favorite : Icons.favorite_border,
          label: post.likeCount > 0 ? '${post.likeCount}' : 'Like',
          color: post.liked ? AppColors.danger : null,
          onTap: () => ctrl.toggleLike(post.id),
        ),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: post.comments.isNotEmpty
              ? '${post.comments.length}'
              : 'Comment',
          onTap: () => _openComments(context, ref),
        ),
        _ActionButton(
          icon: post.bookmarked ? Icons.bookmark : Icons.bookmark_border,
          label: 'Save',
          color: post.bookmarked ? AppColors.bookmark : null,
          onTap: () => ctrl.toggleBookmark(post.id),
        ),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () => ctrl.share(post.id),
        ),
      ],
    );
  }

  void _openComments(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            top: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comments', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (post.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No comments yet — be the first.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                )
              else
                ...post.comments.map(
                  (c) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Text('• $c'),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment…',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      ref
                          .read(feedControllerProvider.notifier)
                          .addComment(post.id, controller.text);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurfaceVariant;
    return InkWell(
      borderRadius: AppRadius.borderSm,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsPreview extends StatelessWidget {
  final FeedPost post;
  const _CommentsPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: post.comments
            .take(2)
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  c,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz
// ---------------------------------------------------------------------------

class _QuizBody extends ConsumerWidget {
  final FeedPost post;
  const _QuizBody({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = post.quiz!;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(quiz.prompt, style: text.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < quiz.options.length; i++)
          _QuizOption(post: post, index: i),
      ],
    );
  }
}

class _QuizOption extends ConsumerWidget {
  final FeedPost post;
  final int index;
  const _QuizOption({required this.post, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = post.quiz!;
    final cs = Theme.of(context).colorScheme;
    final answered = quiz.isAnswered;
    final isCorrect = index == quiz.correct;
    final isPicked = quiz.answered == index;

    Color border = cs.outlineVariant;
    Color? fill;
    IconData? icon;
    if (answered) {
      if (isCorrect) {
        border = AppColors.success;
        fill = AppColors.success.withValues(alpha: 0.12);
        icon = Icons.check_circle;
      } else if (isPicked) {
        border = AppColors.danger;
        fill = AppColors.danger.withValues(alpha: 0.12);
        icon = Icons.cancel;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        borderRadius: AppRadius.borderMd,
        onTap: answered
            ? null
            : () => ref
                  .read(feedControllerProvider.notifier)
                  .answerQuiz(post.id, index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(quiz.options[index])),
              if (icon != null) Icon(icon, size: 18, color: border),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SRS review
// ---------------------------------------------------------------------------

class _SrsBody extends ConsumerWidget {
  final FeedPost post;
  const _SrsBody({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final srs = post.srs!;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final base = text.bodyMedium!.copyWith(color: cs.onSurface, height: 1.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          srs.term,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (srs.pronunciation.isNotEmpty)
          Text(
            srs.pronunciation,
            style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: AppSpacing.xs),
        if (srs.meaning.isNotEmpty) Text(srs.meaning, style: base),
        if (srs.example.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(srs.example, style: base.copyWith(fontStyle: FontStyle.italic)),
        ],
        if (srs.persian.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          RichHtml('🇮🇷 <tg-spoiler>${srs.persian}</tg-spoiler>', style: base),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (srs.isAnswered)
          Text(
            srs.known! ? '✅ Marked as known' : '❌ We\'ll show it again soon',
            style: text.labelMedium?.copyWith(
              color: srs.known! ? AppColors.success : AppColors.danger,
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(feedControllerProvider.notifier)
                      .answerSrs(post.id, true),
                  icon: const Icon(
                    Icons.check,
                    size: 18,
                    color: AppColors.success,
                  ),
                  label: const Text('Knew it'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(feedControllerProvider.notifier)
                      .answerSrs(post.id, false),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  label: const Text('Forgot'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Drill carousel (swipeable pages with dots)
// ---------------------------------------------------------------------------

class _DrillCarousel extends StatefulWidget {
  final FeedPost post;
  const _DrillCarousel({required this.post});

  @override
  State<_DrillCarousel> createState() => _DrillCarouselState();
}

class _DrillCarouselState extends State<_DrillCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drill = widget.post.drill!;
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: cs.onSurface, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: drill.pageCount,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => SingleChildScrollView(
              child: RichHtml(drill.pages[i], style: base),
            ),
          ),
        ),
        if (drill.pageCount > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < drill.pageCount; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

String _kindEmoji(PostKind kind) {
  switch (kind) {
    case PostKind.word:
      return '📘';
    case PostKind.drill:
      return '🎯';
    case PostKind.idiom:
      return '🗣️';
    case PostKind.collocation:
      return '🔗';
    case PostKind.story:
      return '📖';
    case PostKind.tip:
      return '💡';
    case PostKind.quiz:
      return '🧩';
    case PostKind.srs:
      return '🔁';
    case PostKind.text:
      return '✨';
  }
}

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${(d.inDays / 7).floor()}w';
}
