import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/google_sign_in_service.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isLogin) {
      await auth.loginWithEmail(email, password);
    } else {
      final name = _nameController.text.trim();
      await auth.register(email, password, name);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!GoogleSignInService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-in isn't configured yet.")),
      );
      return;
    }
    try {
      final idToken = await GoogleSignInService.signIn();
      if (idToken == null) return; // user canceled
      await ref.read(authProvider.notifier).loginWithGoogle(idToken);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.school,
                    size: AppSpacing.massive,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Engram',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'AI-powered English practice',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  if (!_isLogin)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                  if (!_isLogin) const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!v.contains('@')) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      auth.error!,
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? SizedBox(
                            height: AppSpacing.xl,
                            width: AppSpacing.xl,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(_isLogin ? 'Sign In' : 'Create Account'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                    }),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : 'Already have an account? Sign In',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          'OR',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TelegramCodeScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.telegram, color: AppColors.telegram),
                    label: const Text('Continue with Telegram'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.telegram),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: auth.isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info?.version ?? '';
          final build = info?.buildNumber ?? '';
          // Surface the build number and build mode so a stale or debug sideload
          // is obvious at a glance (this caused a "version doesn't match" report).
          const mode = kReleaseMode
              ? ''
              : (kProfileMode ? ' · profile' : ' · debug');
          final label = version.isEmpty
              ? 'Engram'
              : 'Engram v$version'
                    '${build.isEmpty ? '' : ' ($build)'}$mode';
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }
}

class TelegramCodeScreen extends ConsumerStatefulWidget {
  const TelegramCodeScreen({super.key});

  @override
  ConsumerState<TelegramCodeScreen> createState() => _TelegramCodeScreenState();
}

class _TelegramCodeScreenState extends ConsumerState<TelegramCodeScreen>
    with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  bool _hasOpenedTelegram = false;
  // Guard against overlapping submits (e.g. double-tap). Auto-detect only fills
  // the field — it never submits — so the resume lifecycle can't race or
  // resubmit a single-use code.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasOpenedTelegram) {
      dev.log(
        '[TelegramCode] App resumed, checking clipboard...',
        name: 'TelegramCode',
      );
      _tryAutoDetectCode();
    }
  }

  Future<void> _tryAutoDetectCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim().toUpperCase();
      if (text != null && RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{3}$').hasMatch(text)) {
        if (_submitting || ref.read(authProvider).isAuthenticated) return;
        // Auto-FILL only — never auto-submit. The user taps "Sign In" to redeem
        // the single-use code, so the resume lifecycle can't consume it (or race
        // another installed build for it).
        dev.log('[TelegramCode] Auto-detected code', name: 'TelegramCode');
        _codeController.text = text;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code detected — tap "Sign In with Code"'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      dev.log('[TelegramCode] Clipboard check failed', name: 'TelegramCode');
    }
  }

  Future<void> _submitCode(String code) async {
    // Ignore overlapping submits (e.g. double-tap) while one is in flight.
    if (_submitting) return;
    setState(() => _submitting = true);
    final auth = ref.read(authProvider.notifier);
    final success = await auth.loginWithShortCode(code);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      // Authenticated — leave this screen so the auth gate shows the app. The
      // ref.listen in build() also covers this, but pop here for immediacy.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Invalid or expired code'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _openTelegram() async {
    final botUsername = botTelegramUsername.replaceFirst('@', '');
    final uri = Uri.parse('https://t.me/$botUsername');
    try {
      _hasOpenedTelegram = true;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Telegram. Please install it from the Play Store.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Once authenticated, leave this screen so the auth gate shows the app
    // (covers the auto-detect path and guards against lingering on a stale
    // screen that would keep resubmitting a used code).
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Telegram Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.telegram,
                size: AppSpacing.massive,
                color: AppColors.telegram,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Login with Telegram',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Steps:', style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      const Text('1. Tap "Open Telegram" below'),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('2. Send /login to the bot'),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('3. Copy the code it replies with'),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('4. Return here — the code auto-fills below'),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('5. Tap "Sign In with Code"'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: auth.isLoading ? null : _openTelegram,
                icon: const Icon(Icons.telegram, color: AppColors.telegram),
                label: const Text('Open Telegram'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.telegram),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      'Enter code manually',
                      style: textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'A3F-K9M',
                  hintStyle: textTheme.headlineSmall?.copyWith(
                    letterSpacing: 6,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
                maxLength: 7,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) => null,
                onChanged: (v) {
                  final upper = v.toUpperCase();
                  if (v != upper) {
                    _codeController.value = TextEditingValue(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: auth.isLoading
                    ? null
                    : () {
                        final code = _codeController.text.trim().toUpperCase();
                        if (code.isNotEmpty) {
                          _submitCode(code);
                        }
                      },
                icon: const Icon(Icons.login),
                label: const Text('Sign In with Code'),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  auth.error!,
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
