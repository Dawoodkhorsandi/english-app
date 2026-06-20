import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/telegram_html.dart';
import '../models/chat_message.dart';
import '../providers.dart';

/// Renders one chat message as the appropriate Telegram-style bubble.
class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.kind == ChatKind.typing) return const _TypingBubble();

    final isUser = message.sender == ChatSender.user;
    final cs = Theme.of(context).colorScheme;

    final Color bg = isUser ? AppColors.telegram : cs.surfaceContainerHighest;
    final Color fg = isUser ? Colors.white : cs.onSurface;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.xl),
      topRight: const Radius.circular(AppRadius.xl),
      bottomLeft: Radius.circular(isUser ? AppRadius.xl : AppRadius.xs),
      bottomRight: Radius.circular(isUser ? AppRadius.xs : AppRadius.xl),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: isUser
              ? null
              : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _body(context, ref, fg),
            const SizedBox(height: AppSpacing.xxs),
            _Timestamp(time: message.time, onBlue: isUser),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Color fg) {
    final base = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: fg, height: 1.35);
    switch (message.kind) {
      case ChatKind.quiz:
        return _QuizBody(message: message);
      case ChatKind.srs:
        return _SrsBody(message: message);
      case ChatKind.drill:
        return _DrillBody(message: message);
      case ChatKind.word:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TelegramHtml(message.html, style: base),
            _BookmarkRow(message: message),
          ],
        );
      default:
        return TelegramHtml(message.html, style: base);
    }
  }
}

class _Timestamp extends StatelessWidget {
  final DateTime time;
  final bool onBlue;
  const _Timestamp({required this.time, required this.onBlue});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = onBlue
        ? Colors.white.withValues(alpha: 0.8)
        : cs.onSurfaceVariant;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(time),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color, fontSize: 10),
          ),
          if (onBlue) ...[
            const SizedBox(width: 2),
            Icon(Icons.done_all, size: 12, color: color),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'typing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkRow extends ConsumerWidget {
  final ChatMessage message;
  const _BookmarkRow({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final term = message.term;
    if (term == null || term.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => ref
            .read(feedControllerProvider.notifier)
            .toggleBookmark(message.id),
        icon: Icon(
          message.bookmarked ? Icons.star : Icons.star_border,
          size: 18,
          color: message.bookmarked ? AppColors.bookmark : null,
        ),
        label: Text(message.bookmarked ? 'Bookmarked' : 'Bookmark'),
      ),
    );
  }
}

class _QuizBody extends ConsumerWidget {
  final ChatMessage message;
  const _QuizBody({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = message.quiz!;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('🧩 '),
            Expanded(
              child: Text(
                quiz.prompt,
                style: text.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < quiz.options.length; i++)
          _QuizOption(message: message, index: i),
      ],
    );
  }
}

class _QuizOption extends ConsumerWidget {
  final ChatMessage message;
  final int index;
  const _QuizOption({required this.message, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = message.quiz!;
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
                  .answerQuiz(message.id, index),
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

class _SrsBody extends ConsumerWidget {
  final ChatMessage message;
  const _SrsBody({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final srs = message.srs!;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final base = text.bodyMedium!.copyWith(color: cs.onSurface, height: 1.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '📖 Time to review:',
          style: text.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
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
          // Reuse the spoiler renderer so the Persian gloss is tap-to-reveal.
          TelegramHtml(
            '🇮🇷 <tg-spoiler>${srs.persian}</tg-spoiler>',
            style: base,
          ),
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
                      .answerSrs(message.id, true),
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
                      .answerSrs(message.id, false),
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

class _DrillBody extends ConsumerWidget {
  final ChatMessage message;
  const _DrillBody({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drill = message.drill!;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final base = text.bodyMedium!.copyWith(color: cs.onSurface, height: 1.4);
    final page = drill.page.clamp(0, drill.pageCount - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TelegramHtml(drill.pages[page], style: base),
        if (drill.pageCount > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: page > 0
                    ? () => ref
                          .read(feedControllerProvider.notifier)
                          .setDrillPage(message.id, page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${page + 1} / ${drill.pageCount}',
                style: text.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: page < drill.pageCount - 1
                    ? () => ref
                          .read(feedControllerProvider.notifier)
                          .setDrillPage(message.id, page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
