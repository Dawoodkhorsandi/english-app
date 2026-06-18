import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/auth/auth_provider.dart';
import 'shared/navigation/app_router.dart';
import 'features/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: EnglishApp()));
}

class EnglishApp extends ConsumerWidget {
  const EnglishApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'English Muscle Memory',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: auth.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isAuthenticated
          ? const MainShell()
          : const LoginScreen(),
    );
  }
}
