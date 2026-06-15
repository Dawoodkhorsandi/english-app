import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../core/theme/app_spacing.dart';

class PracticeScreen extends ConsumerWidget {
  final String kind;
  const PracticeScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final practiceAsync = ref.watch(practiceProvider(kind));

    return Scaffold(
      appBar: AppBar(
        title: Text('${kind[0].toUpperCase()}${kind.substring(1)} Practice'),
      ),
      body: practiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading $kind')),
        data: (data) {
          if (data == null) {
            return Center(child: Text('No $kind available right now.'));
          }
          return Center(
            child: Card(
              margin: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['term'] ?? '',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      data['text'] ?? '',
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
