import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  String? _jwtToken;
  // Single-flight guard so a burst of concurrent 401s triggers at most one
  // token refresh rather than a stampede.
  Future<bool>? _refreshing;

  /// Called after [clearAuth] wipes the JWT so that higher layers (e.g.
  /// [AuthNotifier]) can reset their own state. This avoids a stale
  /// "authenticated" UI when the interceptor logs the user out server-side.
  VoidCallback? onAuthCleared;

  ApiClient({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: requestTimeout,
        receiveTimeout: requestTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (kDebugMode) {
      // Headers and bodies are intentionally NOT logged: auth requests carry
      // passwords and responses carry JWTs. Log only method, path, status and
      // timing so debug builds never leak credentials to the console/logcat.
      _dio.interceptors.add(
        PrettyDioLogger(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  void setJwtToken(String token) {
    _jwtToken = token;
    _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> loadStoredAuth() async {
    _jwtToken = await _storage.read(key: 'jwt_token');
    // Clear any credential left by the retired Telegram-initData login path.
    await _storage.delete(key: 'telegram_init_data');
  }

  Future<void> clearAuth() async {
    _jwtToken = null;
    await _storage.delete(key: 'jwt_token');
    onAuthCleared?.call();
  }

  bool get isAuthenticated => _jwtToken != null;

  String? get currentToken => _jwtToken;

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  /// Exchanges the current JWT for a fresh one via /api/auth/refresh. Calls are
  /// single-flighted; returns true when a new token was stored.
  Future<bool> tryRefresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final token = _jwtToken;
    if (token == null) return false;
    try {
      // A bare Dio (no interceptors) so a 401 on refresh can't recurse back in.
      final res =
          await Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: requestTimeout,
              receiveTimeout: requestTimeout,
            ),
          ).post(
            '/api/auth/refresh',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      final newToken = res.data is Map ? res.data['token'] as String? : null;
      if (newToken != null && newToken.isNotEmpty) {
        setJwtToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      dev.log('[Auth] Token refresh failed', name: 'ApiClient');
      return false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _client._jwtToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    // Auth mutation endpoints (login/register/verify) should NOT trigger a
    // token-refresh cycle on 401 — a 401 there means bad credentials, not an
    // expired session. /api/auth/me is excluded: it's a session probe and a 401
    // there means the token expired and SHOULD be refreshed.
    final isAuthMutation = path.contains('/api/auth/') && !path.endsWith('/me');
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (status == 401 &&
        !isAuthMutation &&
        _client._jwtToken != null &&
        !alreadyRetried) {
      // The token likely expired mid-session. Refresh once and replay the
      // original request before giving up — so a stale token no longer kicks
      // the user back to the login screen.
      final refreshed = await _client.tryRefresh();
      if (refreshed) {
        try {
          final opts = err.requestOptions;
          opts.extra['retried'] = true;
          opts.headers['Authorization'] = 'Bearer ${_client._jwtToken}';
          final clone = await _client._dio.fetch<dynamic>(opts);
          return handler.resolve(clone);
        } catch (_) {
          // Refresh succeeded but the replay still failed — fall through.
        }
      }
      await _client.clearAuth();
    } else if (status == 401 && !isAuthMutation) {
      await _client.clearAuth();
    }
    handler.next(err);
  }
}
