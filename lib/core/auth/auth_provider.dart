import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

enum AuthMethod { telegram, email, none }

class AuthState {
  final AuthMethod method;
  final bool isLoading;
  final String? error;
  final String? email;
  final String? name;

  AuthState({
    this.method = AuthMethod.none,
    this.isLoading = false,
    this.error,
    this.email,
    this.name,
  });

  AuthState copyWith({
    AuthMethod? method,
    bool? isLoading,
    String? error,
    String? email,
    String? name,
    bool clearError = false,
  }) {
    return AuthState(
      method: method ?? this.method,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  bool get isAuthenticated => method != AuthMethod.none;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _apiClient.loadStoredAuth();

    // Restore the session from the stored JWT (the single credential the app
    // uses; the interceptor silently refreshes it if it has expired).
    if (_apiClient.currentToken != null) {
      try {
        final response = await _apiClient.get('/api/auth/me');
        final data = response.data as Map<String, dynamic>;
        final email = data['email'] as String?;
        final hasTelegram = data['telegram_chat_id'] != null;
        state = AuthState(
          method: (email == null || email.isEmpty) && hasTelegram
              ? AuthMethod.telegram
              : AuthMethod.email,
          email: email,
          name: data['name'] as String?,
        );
        dev.log('[Auth] Session restored', name: 'Auth');
        return;
      } catch (e) {
        dev.log('[Auth] Session restore failed', name: 'Auth');
        _apiClient.clearAuth();
      }
    }

    state = AuthState();
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      final token = data['token'] as String;
      _apiClient.setJwtToken(token);
      state = AuthState(
        method: AuthMethod.email,
        email: email,
        name: data['name'],
      );
      dev.log('[Auth] Email login success', name: 'Auth');
    } catch (e) {
      dev.log('[Auth] Email login failed', name: 'Auth');
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please check your credentials.',
      );
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post(
        '/api/auth/register',
        data: {'email': email, 'password': password, 'name': name},
      );
      final data = response.data;
      final token = data['token'] as String;
      _apiClient.setJwtToken(token);
      state = AuthState(method: AuthMethod.email, email: email, name: name);
      dev.log('[Auth] Registration success', name: 'Auth');
    } catch (e) {
      dev.log('[Auth] Registration failed', name: 'Auth');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Email may already be in use.',
      );
    }
  }

  Future<bool> loginWithShortCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post(
        '/api/auth/telegram/verify',
        data: {'code': code},
      );
      final data = response.data;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      _apiClient.setJwtToken(token);
      state = AuthState(
        method: AuthMethod.telegram,
        name: user['name'] as String?,
      );
      dev.log('[Auth] Short code login success', name: 'Auth');
      return true;
    } catch (e) {
      dev.log('[Auth] Short code verification failed', name: 'Auth');
      String errorMsg = 'Invalid or expired code. Get a new one from the bot.';
      if (e.toString().contains('401')) {
        errorMsg = 'Code expired or already used. Get a new one from the bot.';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    _apiClient.clearAuth();
    state = AuthState();
    dev.log('[Auth] Logged out', name: 'Auth');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
