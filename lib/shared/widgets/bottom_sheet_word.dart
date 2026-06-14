import 'package:flutter/material.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            term,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (pronunciation != null && pronunciation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pronunciation!,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
          if (persian != null && persian!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(persian!, style: const TextStyle(fontSize: 18)),
          ],
          if (meaning != null && meaning!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(meaning!),
          ],
          if (example != null && example!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              example!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
          const SizedBox(height: 16),
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
