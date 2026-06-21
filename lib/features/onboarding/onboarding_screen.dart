import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

/// One word offered during known-word onboarding.
class _OnboardWord {
  final String term;
  final String persian;
  _OnboardWord(this.term, this.persian);
}

/// GET /api/onboarding → {onboarded, words:[{term, persian, ...}]}.
final onboardingWordsProvider = FutureProvider<List<_OnboardWord>>((ref) async {
  final client = ref.read(apiClientProvider);
  final res = await client.get(
    ApiEndpoints.onboarding,
    queryParameters: {'limit': 40},
  );
  if (res.data['onboarded'] == true) return [];
  return ((res.data['words'] as List?) ?? [])
      .map((w) => _OnboardWord(w['term'] ?? '', w['persian'] ?? ''))
      .where((w) => w.term.isNotEmpty)
      .toList();
});

/// Known-word onboarding: the user taps the common words they already know so
/// study skips them, surfacing only what's new (frequency-ranked).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _known = {};
  bool _submitting = false;

  Future<void> _finish(List<String> known) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(ApiEndpoints.onboarding, data: {'known': known});
    } catch (_) {
      // best-effort; don't trap the user on the onboarding screen
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final wordsAsync = ref.watch(onboardingWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome 👋'),
        automaticallyImplyLeading: false,
      ),
      body: wordsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: LoadingSkeleton(lines: 8),
        ),
        error: (e, _) => ErrorState(
          message: 'Could not load onboarding',
          onRetry: () => ref.invalidate(onboardingWordsProvider),
        ),
        data: (words) {
          // Nothing to triage (already onboarded / empty) — leave immediately.
          if (words.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Which of these do you already know?',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Tap every word you know well — we'll skip them so you "
                      'only study what\'s new.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.chipGap,
                    runSpacing: AppSpacing.chipGap,
                    children: words
                        .map(
                          (w) => FilterChip(
                            label: Text(w.term),
                            selected: _known.contains(w.term),
                            onSelected: (sel) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (sel) {
                                  _known.add(w.term);
                                } else {
                                  _known.remove(w.term);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : () => _finish([]),
                          child: const Text("I'm a beginner"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting
                              ? null
                              : () => _finish(_known.toList()),
                          child: Text(
                            _known.isEmpty
                                ? 'Continue'
                                : 'Continue (${_known.length})',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
