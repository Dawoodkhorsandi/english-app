import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../../core/models/leaderboard.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class ProfileDetailScreen extends ConsumerWidget {
  final String userId;
  const ProfileDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            Center(child: Text('User not found', style: textTheme.bodyLarge)),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: AppSpacing.xxxl,
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name[0].toUpperCase()
                            : '?',
                        style: textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      profile.name.isNotEmpty ? profile.name : 'Anonymous',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('\u{1F44F}'),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${profile.kudos.count}'),
                        if (!profile.isMe) ...[
                          const SizedBox(width: AppSpacing.md),
                          IconButton(
                            icon: Icon(
                              profile.kudos.gaveByMe
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                            ),
                            onPressed: () async {
                              final client = ref.read(apiClientProvider);
                              await client.post(
                                ApiEndpoints.kudos,
                                data: {'id': userId},
                              );
                              ref.invalidate(profileProvider(userId));
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...profile.metrics.map(
              (m) => _versusRow(m, colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _versusRow(
    VersusMetric m,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final total = m.me + m.them;
    final mePct = total > 0 ? m.me / total : 0.5;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.label,
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('${m.me}', style: textTheme.bodyMedium),
                Expanded(
                  child: Container(
                    height: AppSpacing.sm,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(borderRadius: AppRadius.borderXs),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (mePct * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: AppRadius.borderXs,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((1 - mePct) * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              borderRadius: AppRadius.borderXs,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text('${m.them}', style: textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
