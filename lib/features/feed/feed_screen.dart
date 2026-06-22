import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'providers.dart';
import 'widgets/feed_cards.dart';

/// The "Feed" tab: a social-media-style feed of learning posts (content pool +
/// injected quiz/review), with pull-to-refresh, infinite scroll, and a compose
/// FAB for word lookups.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        child: const Icon(Icons.add),
      ),
      body: _body(state),
    );
  }

  Widget _body(FeedState state) {
    if (state.loading && state.posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.pagePadding),
        child: LoadingSkeleton(lines: 8),
      );
    }
    if (state.error != null && state.posts.isEmpty) {
      return ErrorState(
        message: 'Could not load the feed',
        onRetry: () => ref.read(feedControllerProvider.notifier).loadInitial(),
      );
    }
    if (state.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.dynamic_feed_outlined,
        title: 'Nothing here yet',
        subtitle: 'Pull to refresh, or tap + to look up a word.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          AppSpacing.huge,
        ),
        itemCount: state.posts.length + 1,
        itemBuilder: (context, i) {
          if (i == state.posts.length) {
            return state.hasMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: AppSpacing.xl);
          }
          return FeedCard(post: state.posts[i]);
        },
      ),
    );
  }

  void _openCompose() {
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
            top: AppSpacing.sm,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Look up a word',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Type a word (English or Persian)…',
                ),
                onSubmitted: (_) => _submitCompose(ctx, controller.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => _submitCompose(ctx, controller.text),
                  child: const Text('Look up'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitCompose(BuildContext sheetCtx, String text) {
    if (text.trim().isEmpty) return;
    Navigator.of(sheetCtx).pop();
    ref.read(feedControllerProvider.notifier).lookup(text);
  }
}
