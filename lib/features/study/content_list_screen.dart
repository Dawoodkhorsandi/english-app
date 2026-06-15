import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../library/providers.dart';
import '../../core/models/content_item.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';

class ContentListScreen extends ConsumerWidget {
  final String kind;
  final String title;
  const ContentListScreen({super.key, required this.kind, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final contentAsync = ref.watch(contentProvider(kind));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: contentAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: LoadingSkeleton(lines: 6),
        ),
        error: (e, _) => ErrorState(
          message: 'Could not load $title',
          onRetry: () => ref.invalidate(contentProvider(kind)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No $title yet',
              subtitle: 'Content will appear here as it\'s added.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showContentDetail(context, item),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.term,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.meaning.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            item.meaning,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                        if (item.text.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
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

  void _showContentDetail(BuildContext context, ContentItem item) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                item.term,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.meaning.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.meaning,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
              if (item.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  item.text,
                  style: textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
              ],
              if (item.sentAt.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  item.sentAt,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
