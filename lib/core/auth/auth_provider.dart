import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Extracts the backend's error text from a failed request. The auth endpoints
/// reply with a plain-text body (e.g. "code already used") on 4xx, or a JSON
/// {"error": ...} on some routes. Returns '' when nothing useful is present.
String _serverError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map && data['error'] != null) return data['error'].toString();
  }
  return '';
}

/// True when the request never got a usable HTTP response from the server
/// (connection refused/timeout/DNS, or a gateway error with no parsable body).
/// These are network/outage conditions — not a rejected login code — so the UI
/// must not tell the user their code is wrong. A bot redeploy briefly restarts
/// the container (nginx 502), which lands here.
bool _isNetworkError(Object e) {
  if (e is! DioException) return false;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return true;
    case DioExceptionType.unknown:
      // No HTTP response at all — typically a SocketException or similar.
      return e.response == null;
    case DioExceptionType.badResponse:
      // 5xx / gateway errors with no actionable body are server-side outages.
      final status = e.response?.statusCode ?? 0;
      return status >= 500 && _serverError(e).isEmpty;
    default:
      return false;
  }
}

enum AuthMethod { telegram, email, google, none }

class AuthState {
  final AuthMethod method;
  final bool isLoading;
  final String? error;
  final String? email;
  final String? name;
  final bool telegramConnected;

  AuthState({
    this.method = AuthMethod.none,
    this.isLoading = false,
    this.error,
    this.email,
    this.name,
    this.telegramConnected = false,
  });

  AuthState copyWith({
    AuthMethod? method,
    bool? isLoading,
    String? error,
    String? email,
    String? name,
    bool? telegramConnected,
    bool clearError = false,
  }) {
    return AuthState(
      method: method ?? this.method,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      email: email ?? this.email,
      name: name ?? this.name,
      telegramConnected: telegramConnected ?? this.telegramConnected,
    );
  }

  bool get isAuthenticated => method != AuthMethod.none;

  /// The user's real display name, or null when none has been set.
  ///
  /// The backend uses a placeholder (`User <telegram_id>`) — or sometimes the
  /// bare numeric id — for Telegram users who never set a name. We must never
  /// surface that id to the user, so treat those as "no name".
  String? get displayName {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return null;
    if (RegExp(r'^User\s*\d+$', caseSensitive: false).hasMatch(n)) return null;
    if (RegExp(r'^\d+$').hasMatch(n)) return null;
    return n;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _apiClient.onAuthCleared = _onAuthCleared;
    _init();
  }

  /// Called by [ApiClient] when the 401 interceptor wipes the JWT.
  void _onAuthCleared() {
    // Guard against calls after dispose (e.g. a late-arriving 401 response).
    if (!mounted) return;
    state = AuthState();
  }

  @override
  void dispose() {
    _apiClient.onAuthCleared = null;
    super.dispose();
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
          telegramConnected: hasTelegram,
        );
        dev.log('[Auth] Session restored', name: 'Auth');
        return;
      } catch (e) {
        dev.log('[Auth] Session restore failed', name: 'Auth');
        await _apiClient.clearAuth();
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
      final user = data['user'] as Map<String, dynamic>?;
      _apiClient.setJwtToken(token);
      state = AuthState(
        method: AuthMethod.email,
        email: email,
        name: user?['name'] as String?,
        telegramConnected: user?['telegram_chat_id'] != null,
      );
      dev.log('[Auth] Email login success', name: 'Auth');
    } catch (e) {
      dev.log('[Auth] Email login failed', name: 'Auth');
      state = state.copyWith(
        isLoading: false,
        error: _isNetworkError(e)
            ? "Couldn't reach the server. Check your connection and try again."
            : 'Login failed. Please check your credentials.',
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
        error: _isNetworkError(e)
            ? "Couldn't reach the server. Check your connection and try again."
            : 'Registration failed. Email may already be in use.',
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
        telegramConnected: true,
      );
      dev.log('[Auth] Short code login success', name: 'Auth');
      return true;
    } catch (e) {
      dev.log('[Auth] Short code verification failed', name: 'Auth');
      // A connection/outage failure must not be reported as a bad code (e.g. a
      // bot redeploy briefly 502s) — surface it as a network problem instead.
      if (_isNetworkError(e)) {
        state = state.copyWith(
          isLoading: false,
          error:
              "Couldn't reach the server. Check your connection and try again "
              'in a moment — your code may still be valid.',
        );
        return false;
      }
      // Surface the exact backend reason so "invalid" vs "used" vs "expired"
      // is no longer ambiguous.
      final reason = _serverError(e);
      String errorMsg;
      switch (reason) {
        case 'code already used':
          errorMsg =
              'That code was already used. Send /login to the bot for a fresh code.';
          break;
        case 'code expired':
          errorMsg =
              'That code expired (codes last 5 minutes). Send /login for a new one.';
          break;
        case 'invalid code':
          errorMsg =
              "That code wasn't recognised. Re-check it, or send /login for a new one.";
          break;
        default:
          errorMsg = reason.isNotEmpty
              ? 'Login failed: $reason'
              : 'Login failed. Send /login to the bot for a fresh code.';
      }
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;
    }
  }

  /// Exchanges a Google ID token (obtained natively on-device) for an app JWT.
  Future<bool> loginWithGoogle(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authGoogle,
        data: {'id_token': idToken},
      );
      final data = response.data;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>?;
      _apiClient.setJwtToken(token);
      state = AuthState(
        method: AuthMethod.google,
        email: user?['email'] as String?,
        name: user?['name'] as String?,
        telegramConnected: user?['telegram_chat_id'] != null,
      );
      dev.log('[Auth] Google login success', name: 'Auth');
      return true;
    } catch (e) {
      dev.log('[Auth] Google login failed', name: 'Auth');
      state = state.copyWith(
        isLoading: false,
        error: _isNetworkError(e)
            ? "Couldn't reach the server. Check your connection and try again."
            : 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Links a Google identity to the signed-in account, then refreshes the
  /// profile. Requires an existing session (Bearer JWT).
  Future<String?> linkGoogle(String idToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authLinkGoogle,
        data: {'id_token': idToken},
      );
      final err = response.data is Map ? response.data['error'] : null;
      if (err != null) return err.toString();
      await reloadProfile();
      return null;
    } catch (e) {
      return _isNetworkError(e)
          ? "Couldn't reach the server. Try again."
          : 'Could not link Google.';
    }
  }

  /// Links a Telegram account using a one-time code from the bot's /login.
  /// The Telegram side is canonical, so the backend may return a fresh token
  /// for the merged account. Returns null on success or an error message.
  Future<String?> linkTelegram(String code) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authLinkTelegram,
        data: {'code': code.trim().toUpperCase()},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      final token = data['token'] as String?;
      if (token != null) _apiClient.setJwtToken(token);
      await reloadProfile();
      return null;
    } catch (e) {
      return _isNetworkError(e)
          ? "Couldn't reach the server. Try again in a moment."
          : 'That code was not accepted. Send /login to the bot for a new one.';
    }
  }

  /// Re-fetches the profile from /api/auth/me and updates state (name,
  /// email, telegramConnected) without changing the session.
  Future<void> reloadProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.authMe);
      final data = response.data as Map<String, dynamic>;
      final email = data['email'] as String?;
      final hasTelegram = data['telegram_chat_id'] != null;
      state = state.copyWith(
        method: (email == null || email.isEmpty) && hasTelegram
            ? AuthMethod.telegram
            : state.method == AuthMethod.none
            ? AuthMethod.email
            : state.method,
        email: email,
        name: data['name'] as String?,
        telegramConnected: hasTelegram,
      );
    } catch (e) {
      dev.log('[Auth] reloadProfile failed', name: 'Auth');
    }
  }

  Future<void> logout() async {
    await _apiClient.clearAuth();
    state = AuthState();
    dev.log('[Auth] Logged out', name: 'Auth');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
