import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../../core/models/leaderboard.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';

class ProfileDetailScreen extends ConsumerWidget {
  final String userId;
  const ProfileDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('User not found')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 8),
                    Text(profile.name.isNotEmpty ? profile.name : 'Anonymous', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('\u{1F44F}'),
                        const SizedBox(width: 4),
                        Text('${profile.kudos.count}'),
                        if (!profile.isMe) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(profile.kudos.gaveByMe ? Icons.thumb_up : Icons.thumb_up_outlined),
                            onPressed: () async {
                              final client = ref.read(apiClientProvider);
                              await client.post(ApiEndpoints.kudos, data: {'id': userId});
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
            const SizedBox(height: 16),
            ...profile.metrics.map((m) => _versusRow(m)),
          ],
        ),
      ),
    );
  }

  Widget _versusRow(VersusMetric m) {
    final total = m.me + m.them;
    final mePct = total > 0 ? m.me / total : 0.5;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${m.me}'),
                Expanded(
                  child: Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (mePct * 100).toInt(),
                          child: Container(decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4))),
                        ),
                        Expanded(
                          flex: ((1 - mePct) * 100).toInt(),
                          child: Container(decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
                        ),
                      ],
                    ),
                  ),
                ),
                Text('${m.them}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}