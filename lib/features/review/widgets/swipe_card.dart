import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class SwipeCard {
  final String front;
  final String? sub;
  final String back;
  final String term;

  /// Structured context fields. When [meaning] is non-null the back renders as
  /// styled blocks (meaning, example, Persian, mnemonic) instead of the flat
  /// [back] string — surfacing context as a first-class part of every card.
  final String? meaning;
  final String? example;
  final String? persian;
  final String? mnemonic;

  SwipeCard({
    required this.front,
    this.sub,
    required this.back,
    required this.term,
    this.meaning,
    this.example,
    this.persian,
    this.mnemonic,
  });

  bool get hasContext => meaning != null && meaning!.isNotEmpty;
}

class SwipeSession extends StatefulWidget {
  final List<SwipeCard> cards;
  final Future<void> Function(SwipeCard card, bool known) onAnswer;
  final String doneText;
  final String emptyText;
  final VoidCallback? onFinish;

  const SwipeSession({
    super.key,
    required this.cards,
    required this.onAnswer,
    this.doneText = 'Session complete!',
    this.emptyText = 'No cards to review.',
    this.onFinish,
  });

  @override
  State<SwipeSession> createState() => _SwipeSessionState();
}

class _SwipeSessionState extends State<SwipeSession> {
  late List<SwipeCard> _queue;
  int _knownCount = 0;
  bool _finished = false;
  bool _flipped = false;
  double _dx = 0;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.cards);
  }

  void _commit(bool known) async {
    if (_queue.isEmpty) return;
    final card = _queue.first;
    HapticFeedback.mediumImpact();
    setState(() {
      if (known) _knownCount++;
      _queue.removeAt(0);
      _dx = 0;
      _flipped = false;
    });
    try {
      await widget.onAnswer(card, known);
    } catch (e) {
      _queue.insert(0, card);
      if (known) _knownCount--;
    }
    if (_queue.isEmpty) {
      setState(() => _finished = true);
      HapticFeedback.heavyImpact();
      widget.onFinish?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.cards.isEmpty) {
      return Center(
        child: Text(
          widget.emptyText,
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
        ),
      );
    }
    if (_finished) {
      return _buildCompletion(colorScheme, textTheme);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '${_queue.length} remaining',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const Spacer(),
              Text(
                '$_knownCount known',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use 30% of screen width as swipe threshold so it scales
              // with device size and feels comfortable on all screens.
              final swipeThreshold = constraints.maxWidth * 0.30;
              return GestureDetector(
                onHorizontalDragUpdate: (d) =>
                    setState(() => _dx += d.delta.dx),
                onHorizontalDragEnd: (d) {
                  if (_dx > swipeThreshold) {
                    _commit(true);
                  } else if (_dx < -swipeThreshold) {
                    _commit(false);
                  } else {
                    setState(() => _dx = 0);
                  }
                },
                onTap: () => setState(() => _flipped = !_flipped),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  transform: Matrix4.identity()
                    ..setTranslation(vm.Vector3(_dx, 0.0, 0.0))
                    ..rotateZ(_dx * 0.0005),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: AppRadius.borderXxl,
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_flipped) ...[
                                  _buildBack(
                                    _queue.first,
                                    colorScheme,
                                    textTheme,
                                  ),
                                ] else ...[
                                  Text(
                                    _queue.first.front,
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_queue.first.sub != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      _queue.first.sub!,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  _flipped ? 'Tap to see front' : 'Tap to flip',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_dx > 40)
                        Positioned(
                          top: AppSpacing.lg,
                          right: AppSpacing.lg,
                          child: Opacity(
                            opacity: (_dx / swipeThreshold).clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Text(
                                'KNEW IT',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_dx < -40)
                        Positioned(
                          top: AppSpacing.lg,
                          left: AppSpacing.lg,
                          child: Opacity(
                            opacity: (-_dx / swipeThreshold).clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Text(
                                'FORGOT',
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _commit(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Forgot'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _commit(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Knew it'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Renders the back of a card. When the card carries structured context it
  /// shows the meaning, a quoted example sentence, the Persian gloss (RTL), and
  /// a mnemonic — each as its own styled block. Falls back to the flat [back]
  /// string for cards that don't supply structured fields.
  Widget _buildBack(
    SwipeCard card,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (!card.hasContext) {
      return Text(
        card.back,
        textAlign: TextAlign.center,
        style: textTheme.bodyLarge?.copyWith(height: 1.6),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          card.meaning!,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(height: 1.5),
        ),
        if (card.example != null && card.example!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.borderMd,
              border: const Border(
                left: BorderSide(color: AppColors.accentBlue, width: 3),
              ),
            ),
            child: Text(
              '“${card.example}”',
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (card.persian != null && card.persian!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '🇮🇷 ${card.persian}',
              textAlign: TextAlign.right,
              style: textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
        ],
        if (card.mnemonic != null && card.mnemonic!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            '💡 ${card.mnemonic}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletion(ColorScheme colorScheme, TextTheme textTheme) {
    final pct = widget.cards.isNotEmpty
        ? (_knownCount / widget.cards.length)
        : 0.0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 8,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            widget.doneText,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$_knownCount known / ${widget.cards.length - _knownCount} forgot',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
