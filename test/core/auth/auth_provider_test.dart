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

  _FakeApiClient({super.storage});

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
        'user': {'name': 'Test User', 'email': 'test@example.com'},
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

    test('loginWithShortCode succeeds and sets telegram method', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      client.setPostResponse('/api/auth/telegram/verify', {
        'token': 'fake-jwt-token',
        'user': {
          'id': 991012762,
          'email': '',
          'name': 'User 991012762',
          'chat_id': 991012762,
        },
      });

      final notifier = AuthNotifier(client);
      await Future.delayed(Duration.zero);

      final ok = await notifier.loginWithShortCode('V8L-A33');
      await Future.delayed(Duration.zero);

      expect(ok, true);
      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.method, AuthMethod.telegram);
      expect(notifier.state.name, 'User 991012762');
      expect(notifier.state.telegramConnected, true);
      // The placeholder id must never be shown as a real name.
      expect(notifier.state.displayName, isNull);
    });

    test(
      'loginWithShortCode maps expired code to a code-specific error',
      () async {
        final storage = _FakeStorage();
        final client = _FakeApiClient(storage: storage);
        const path = '/api/auth/telegram/verify';
        client.setPostError(
          DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: path),
              statusCode: 401,
              data: 'code expired',
            ),
          ),
        );

        final notifier = AuthNotifier(client);
        await Future.delayed(Duration.zero);

        final ok = await notifier.loginWithShortCode('V8L-A33');
        await Future.delayed(Duration.zero);

        expect(ok, false);
        expect(notifier.state.error, contains('expired'));
      },
    );

    test('loginWithShortCode reports a network outage as a connection problem, '
        'not a bad code', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      const path = '/api/auth/telegram/verify';
      // A 502 with no parsable body (e.g. nginx during a bot redeploy).
      client.setPostError(
        DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 502,
            data: null,
          ),
        ),
      );

      final notifier = AuthNotifier(client);
      await Future.delayed(Duration.zero);

      final ok = await notifier.loginWithShortCode('V8L-A33');
      await Future.delayed(Duration.zero);

      expect(ok, false);
      expect(notifier.state.error, contains('reach the server'));
      // Must NOT blame the code.
      expect(notifier.state.error, isNot(contains('/login')));
    });

    test(
      'loginWithShortCode treats a connection error as a network problem',
      () async {
        final storage = _FakeStorage();
        final client = _FakeApiClient(storage: storage);
        const path = '/api/auth/telegram/verify';
        client.setPostError(
          DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionError,
          ),
        );

        final notifier = AuthNotifier(client);
        await Future.delayed(Duration.zero);

        final ok = await notifier.loginWithShortCode('V8L-A33');
        await Future.delayed(Duration.zero);

        expect(ok, false);
        expect(notifier.state.error, contains('reach the server'));
      },
    );

    test('logout clears state', () async {
      final storage = _FakeStorage();
      final client = _FakeApiClient(storage: storage);
      client.setPostResponse('/api/auth/login', {
        'token': 'fake-jwt-token',
        'user': {'name': 'Test User', 'email': 'test@example.com'},
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

  group('AuthState.displayName', () {
    String? d(String? name) => AuthState(name: name).displayName;

    test('returns the name when it is a real name', () {
      expect(d('Alex'), 'Alex');
      expect(d('Mary Jane'), 'Mary Jane');
    });

    test('returns null for the "User <id>" placeholder', () {
      expect(d('User 991012762'), isNull);
      expect(d('user 42'), isNull);
    });

    test('returns null for a bare numeric id', () {
      expect(d('991012762'), isNull);
    });

    test('returns null for empty or missing names', () {
      expect(d(null), isNull);
      expect(d(''), isNull);
      expect(d('   '), isNull);
    });
  });
}
