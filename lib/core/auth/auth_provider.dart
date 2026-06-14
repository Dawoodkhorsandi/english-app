import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _storage;

  AuthNotifier(this._apiClient, [FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage(),
      super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _apiClient.loadStoredAuth();

    // Try JWT first
    if (_apiClient.currentToken != null) {
      try {
        final response = await _apiClient.get('/api/auth/me');
        final data = response.data;
        state = AuthState(
          method: AuthMethod.email,
          email: data['email'],
          name: data['name'],
        );
        dev.log('[Auth] Restored JWT session: ${data['email']}', name: 'Auth');
        return;
      } catch (e) {
        dev.log('[Auth] JWT validation failed: $e', name: 'Auth');
        _apiClient.clearAuth();
      }
    }

    // Try Telegram initData
    if (_apiClient.currentInitData != null) {
      dev.log('[Auth] Trying to restore Telegram session...', name: 'Auth');
      try {
        // Test the initData by calling a lightweight endpoint
        final response = await _apiClient.get('/api/config');
        if (response.statusCode == 200) {
          state = AuthState(method: AuthMethod.telegram);
          dev.log('[Auth] Restored Telegram session', name: 'Auth');
          return;
        }
      } catch (e) {
        dev.log('[Auth] Telegram restore failed: $e', name: 'Auth');
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
      dev.log('[Auth] Email login success: $email', name: 'Auth');
    } catch (e) {
      dev.log('[Auth] Email login failed: $e', name: 'Auth');
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
      dev.log('[Auth] Registration success: $email', name: 'Auth');
    } catch (e) {
      dev.log('[Auth] Registration failed: $e', name: 'Auth');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Email may already be in use.',
      );
    }
  }

  Future<bool> loginWithShortCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      dev.log('[Auth] Verifying short code: $code', name: 'Auth');
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
      dev.log('[Auth] Short code login success: ${user['name']}', name: 'Auth');
      return true;
    } catch (e) {
      dev.log('[Auth] Short code verification failed: $e', name: 'Auth');
      String errorMsg = 'Invalid or expired code. Get a new one from the bot.';
      if (e.toString().contains('401')) {
        errorMsg = 'Code expired or already used. Get a new one from the bot.';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  Future<bool> loginWithClipboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      var initData = data?.text?.trim();
      dev.log(
        '[Auth] Clipboard data: ${initData?.substring(0, initData.length > 50 ? 50 : initData.length)}...',
        name: 'Auth',
      );

      if (initData == null || initData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Clipboard is empty. Tap "Copy Login Code" in the Telegram bot first.',
        );
        return false;
      }

      if (!initData.contains('user=')) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Clipboard does not contain Telegram login data. Tap "Copy Login Code" in the bot.',
        );
        return false;
      }

      // Set the initData and validate with backend
      _apiClient.setTelegramInitData(initData);

      // Test by calling a lightweight endpoint
      try {
        await _apiClient.get('/api/config');
        state = AuthState(method: AuthMethod.telegram);
        dev.log('[Auth] Telegram login success', name: 'Auth');
        return true;
      } catch (e) {
        dev.log('[Auth] Telegram validation failed: $e', name: 'Auth');
        _apiClient.clearAuth();
        state = state.copyWith(
          isLoading: false,
          error:
              'Invalid or expired login data. Please copy a fresh code from the bot.',
        );
        return false;
      }
    } catch (e) {
      dev.log('[Auth] Clipboard read error: $e', name: 'Auth');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to read clipboard: $e',
      );
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
