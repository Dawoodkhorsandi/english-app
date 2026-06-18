import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'deck_study_screen.dart';
import '../../core/models/deck.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/progress_bar.dart';
import '../../shared/widgets/progress_ring.dart';

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;
  const DeckDetailScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final detailAsync = ref.watch(deckDetailProvider(deckId));

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error loading deck')),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            _HeroCard(detail: detail),
            const SizedBox(height: AppSpacing.lg),
            _BoxDistributionCard(detail: detail),
            const SizedBox(height: AppSpacing.xl),
            _StartStudyingButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DeckStudyScreen(deckId: deckId, deckName: deckName),
                ),
              ),
            ),
            if (detail.nextReview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'Next review: ${detail.nextReview}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final DeckDetail detail;
  const _HeroCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final pct = (detail.progressPct).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Text('\u{1F4DA}', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail.name,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (detail.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                detail.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ProgressRing(
              progress: pct / 100.0,
              size: 110,
              strokeWidth: 9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$pct%',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _MiniStat(
                  value: '${detail.total}',
                  label: 'Total',
                  color: colorScheme.onSurface,
                ),
                _MiniStat(
                  value: '${detail.mastered}',
                  label: 'Mastered',
                  color: AppColors.success,
                ),
                _MiniStat(
                  value: '${detail.due}',
                  label: 'Due',
                  color: AppColors.accentBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxDistributionCard extends StatelessWidget {
  final DeckDetail detail;
  const _BoxDistributionCard({required this.detail});

  String _label(BoxDistribution b) {
    if (b.label.isNotEmpty) return b.label;
    if (b.box == 0) return 'Unseen';
    if (b.box == 5) return 'Box 5 (Mastered)';
    return 'Box ${b.box}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxCount = detail.boxes.fold<int>(
      1,
      (m, b) => b.count > m ? b.count : m,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leitner Box Distribution',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final b in detail.boxes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(_label(b), style: textTheme.bodyMedium),
                        ),
                        Text(
                          '${b.count}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    ProgressBar(
                      value: b.count / maxCount,
                      height: AppSpacing.xs,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartStudyingButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartStudyingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderXl,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: AppRadius.borderXl,
          ),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Start Studying',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
