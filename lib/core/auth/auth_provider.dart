import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

enum AuthMethod { telegram, email, none }

class AuthState {
  final AuthMethod method;
  final bool isLoading;
  final String? error;
  final String? email;
  final String? name;

  AuthState({this.method = AuthMethod.none, this.isLoading = false, this.error, this.email, this.name});

  AuthState copyWith({AuthMethod? method, bool? isLoading, String? error, String? email, String? name, bool clearError = false}) {
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
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      _apiClient.setJwtToken(token);
      try {
        final response = await _apiClient.get('/api/auth/me');
        final data = response.data;
        state = AuthState(
          method: AuthMethod.email,
          email: data['email'],
          name: data['name'],
        );
      } catch (e) {
        _apiClient.clearAuth();
        state = AuthState();
      }
    } else {
      state = AuthState();
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post('/api/auth/login', data: {'email': email, 'password': password});
      final data = response.data;
      final token = data['token'] as String;
      _apiClient.setJwtToken(token);
      await _storage.write(key: 'jwt_token', value: token);
      state = AuthState(method: AuthMethod.email, email: email, name: data['name']);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed. Please check your credentials.');
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.post('/api/auth/register', data: {'email': email, 'password': password, 'name': name});
      final data = response.data;
      final token = data['token'] as String;
      _apiClient.setJwtToken(token);
      await _storage.write(key: 'jwt_token', value: token);
      state = AuthState(method: AuthMethod.email, email: email, name: name);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed. Email may already be in use.');
    }
  }

  void setTelegramAuth(String initData) {
    _apiClient.setTelegramInitData(initData);
    state = AuthState(method: AuthMethod.telegram);
  }

  Future<void> logout() async {
    _apiClient.clearAuth();
    await _storage.delete(key: 'jwt_token');
    state = AuthState();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
