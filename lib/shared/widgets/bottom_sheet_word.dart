import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

class WordBottomSheet extends StatelessWidget {
  final String term;
  final String? meaning;
  final String? pronunciation;
  final String? persian;
  final String? example;
  final VoidCallback? onOpenDictionary;
  const WordBottomSheet({
    super.key,
    required this.term,
    this.meaning,
    this.pronunciation,
    this.persian,
    this.example,
    this.onOpenDictionary,
  });

  static void show(
    BuildContext context, {
    required String term,
    String? meaning,
    String? pronunciation,
    String? persian,
    String? example,
    VoidCallback? onOpenDictionary,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => WordBottomSheet(
        term: term,
        meaning: meaning,
        pronunciation: pronunciation,
        persian: persian,
        example: example,
        onOpenDictionary: onOpenDictionary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term,
            style: textTheme.headlineSmall,
          ),
          if (pronunciation != null && pronunciation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              pronunciation!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (persian != null && persian!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              persian!,
              style: textTheme.bodyLarge,
            ),
          ],
          if (meaning != null && meaning!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(meaning!),
          ],
          if (example != null && example!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              example!,
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (onOpenDictionary != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpenDictionary,
                child: const Text('Open in Dictionary'),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
