import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../home/providers.dart';
import '../home/daily_goal_picker.dart';
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

/// Shows whether the account is linked to Telegram, with a hint to connect.
class _TelegramStatusCard extends StatelessWidget {
  final bool connected;
  const _TelegramStatusCard({required this.connected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.send_rounded,
          color: connected ? AppColors.telegram : colorScheme.onSurfaceVariant,
        ),
        title: const Text('Telegram'),
        subtitle: Text(
          connected
              ? 'Connected'
              : 'Not connected · send /start to $botTelegramUsername',
          style: textTheme.bodySmall?.copyWith(
            color: connected ? AppColors.success : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          connected ? Icons.check_circle : Icons.cancel_outlined,
          color: connected ? AppColors.success : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
