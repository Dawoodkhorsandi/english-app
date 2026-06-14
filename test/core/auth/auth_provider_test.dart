import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:english_app/core/auth/auth_provider.dart';
import 'package:english_app/core/api/api_client.dart';

class _FakeStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);
}

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _getResponses = {};
  final Map<String, dynamic> _postResponses = {};
  Object? _postError;

  _FakeApiClient({FlutterSecureStorage? storage}) : super(storage: storage);

  void setGetResponse(String path, dynamic data) {
    _getResponses[path] = data;
  }

  void setPostResponse(String path, dynamic data) {
    _postResponses[path] = data;
  }

  void setPostError(Object error) {
    _postError = error;
  }

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_getResponses.containsKey(path)) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: _getResponses[path],
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {},
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    if (_postError != null) throw _postError!;
    if (_postResponses.containsKey(path)) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: _postResponses[path],
      );
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier', () {
    test('initial state is unauthenticated', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      final notifier = AuthNotifier(client);
      await Future.delayed(Duration.zero);

      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.method, AuthMethod.none);
    });

    test('loginWithEmail stores token and updates state', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      client.setPostResponse('/api/auth/login', {
        'token': 'fake-jwt-token',
        'name': 'Test User',
      });

      final notifier = AuthNotifier(client);
      await Future.delayed(Duration.zero);

      await notifier.loginWithEmail('test@example.com', 'password123');
      await Future.delayed(Duration.zero);

      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.method, AuthMethod.email);
      expect(notifier.state.email, 'test@example.com');
      expect(notifier.state.name, 'Test User');
    });

    test('loginWithEmail shows error on failure', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      client.setPostError(Exception('Network error'));

      final notifier = AuthNotifier(client);
      await Future.delayed(Duration.zero);

      await notifier.loginWithEmail('test@example.com', 'wrong');
      await Future.delayed(Duration.zero);

      expect(notifier.state.isAuthenticated, false);
      expect(
        notifier.state.error,
        'Login failed. Please check your credentials.',
      );
    });

    test('logout clears state', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      client.setPostResponse('/api/auth/login', {
        'token': 'fake-jwt-token',
        'name': 'Test User',
      });

      final notifier = AuthNotifier(client);
      await Future.delayed(Duration.zero);

      await notifier.loginWithEmail('test@example.com', 'password123');
      await Future.delayed(Duration.zero);
      expect(notifier.state.isAuthenticated, true);

      await notifier.logout();
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.method, AuthMethod.none);
      expect(notifier.state.email, isNull);
      expect(notifier.state.name, isNull);
    });
  });
}
