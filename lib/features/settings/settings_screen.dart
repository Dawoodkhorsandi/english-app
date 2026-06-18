import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../core/auth/google_sign_in_service.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../home/providers.dart';
import '../home/daily_goal_picker.dart';
import 'report_bug_screen.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/error_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: settingsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.pagePadding),
          child: LoadingSkeleton(lines: 8),
        ),
        error: (e, s) => ErrorState(
          message: 'Could not load settings',
          onRetry: () => ref.invalidate(settingsProvider),
        ),
        data: (settings) {
          if (_nameController.text.isEmpty && settings.name.isNotEmpty) {
            _nameController.text = settings.name;
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onFieldSubmitted: (v) =>
                        _updateSetting(ref, 'name', v.trim()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TelegramStatusCard(
                connected: ref.watch(authProvider).telegramConnected,
                onConnect: () => _showConnectTelegramDialog(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.g_mobiledata, size: 28),
                  title: const Text('Google'),
                  subtitle: Text(
                    ref.watch(authProvider).method == AuthMethod.google
                        ? 'Signed in with Google'
                        : 'Link your Google account',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _connectGoogle(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.chipGap,
                        children: settings.levels
                            .map(
                              (l) => ChoiceChip(
                                label: Text(settings.levelLabels[l] ?? l),
                                selected: settings.level == l,
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  _updateSetting(ref, 'level', l);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Self-paced mode'),
                      subtitle: const Text('Pause all automatic messages'),
                      value: settings.paused,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        _updateSetting(ref, 'paused', v);
                      },
                    ),
                    ListTile(
                      title: const Text('Send interval'),
                      subtitle: Text('${settings.interval} minutes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _showIntervalDialog(context, ref, settings.interval),
                    ),
                    ...settings.toggles.entries.map(
                      (entry) => SwitchListTile(
                        title: Text(_toggleLabel(entry.key)),
                        value: entry.value,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          _updateSetting(ref, entry.key, v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode, size: 18),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode, size: 18),
                          ),
                        ],
                        selected: {ref.watch(themeModeProvider)},
                        showSelectedIcon: false,
                        onSelectionChanged: (sel) {
                          HapticFeedback.selectionClick();
                          ref.read(themeModeProvider.notifier).set(sel.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  title: const Text('Daily word goal'),
                  subtitle: Text(
                    '${ref.watch(dailyGoalTargetProvider)} words / day',
                  ),
                  leading: const Icon(Icons.flag_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDailyGoalPicker(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  title: const Text('Report a bug'),
                  leading: const Icon(Icons.bug_report_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportBugScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  title: const Text('Logout'),
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, WidgetRef ref, int current) {
    final intervals = [15, 30, 60, 120, 180, 240, 360, 480, 720];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Send interval'),
        children: intervals
            .map(
              (m) => SimpleDialogOption(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(ctx);
                  _updateSetting(ref, 'interval', m);
                },
                child: Row(
                  children: [
                    if (m == current)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.success,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: AppSpacing.md),
                    Text('$m minutes'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Walks the user through linking their Telegram account using a one-time
  // /login code from the bot, then links via authProvider.linkTelegram.
  void _showConnectTelegramDialog(BuildContext context) {
    final codeController = TextEditingController();
    String? error;
    bool busy = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Connect Telegram'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open $botTelegramUsername in Telegram, send /login, '
                'then enter the code it gives you.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Login code',
                  hintText: 'A3F-K9M',
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) {
                        setLocal(() => error = 'Enter the code');
                        return;
                      }
                      setLocal(() {
                        busy = true;
                        error = null;
                      });
                      final err = await ref
                          .read(authProvider.notifier)
                          .linkTelegram(code);
                      if (!ctx.mounted) return;
                      if (err == null) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Telegram connected!')),
                        );
                      } else {
                        setLocal(() {
                          busy = false;
                          error = err;
                        });
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  // Links a Google identity to the signed-in account via native sign-in.
  Future<void> _connectGoogle(BuildContext context) async {
    if (!GoogleSignInService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-in isn't configured yet.")),
      );
      return;
    }
    try {
      final idToken = await GoogleSignInService.signIn();
      if (idToken == null) return; // canceled
      final err = await ref.read(authProvider.notifier).linkGoogle(idToken);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err ?? 'Google account linked!')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _updateSetting(WidgetRef ref, String key, dynamic value) async {
    final client = ref.read(apiClientProvider);
    try {
      await client.post(
        ApiEndpoints.settings,
        data: {'key': key, 'value': value},
      );
      ref.invalidate(settingsProvider);
    } catch (e) {
      // ignore
    }
  }

  String _toggleLabel(String key) {
    switch (key) {
      case 'tts':
        return 'Pronunciation audio';
      case 'tips':
        return 'Daily grammar tips';
      case 'quiz':
        return 'Quiz reminders';
      case 'idiom':
        return 'Idiom of the day';
      case 'collocation':
        return 'Collocation of the day';
      case 'story':
        return 'Mini stories';
      case 'review':
        return 'Review reminders';
      case 'daily_review':
        return 'Daily review';
      case 'digest':
        return 'Weekly digest';
      default:
        return key;
    }
  }
}

/// Shows whether the account is linked to Telegram. When not connected the
/// tile is tappable to start the linking flow.
class _TelegramStatusCard extends StatelessWidget {
  final bool connected;
  final VoidCallback onConnect;
  const _TelegramStatusCard({required this.connected, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: connected ? null : onConnect,
        leading: Icon(
          Icons.send_rounded,
          color: connected ? AppColors.telegram : colorScheme.onSurfaceVariant,
        ),
        title: const Text('Telegram'),
        subtitle: Text(
          connected ? 'Connected' : 'Not connected · tap to connect',
          style: textTheme.bodySmall?.copyWith(
            color: connected ? AppColors.success : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: connected
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
