import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  String? _telegramInitData;
  String? _jwtToken;

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
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          compact: false,
          maxWidth: 90,
        ),
      );
    }
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  void setTelegramInitData(String initData) {
    _telegramInitData = initData;
    _storage.write(key: 'telegram_init_data', value: initData);
    dev.log(
      '[Auth] Telegram initData set (${initData.length} chars)',
      name: 'ApiClient',
    );
  }

  void setJwtToken(String token) {
    _jwtToken = token;
    _storage.write(key: 'jwt_token', value: token);
    dev.log('[Auth] JWT token set', name: 'ApiClient');
  }

  Future<void> loadStoredAuth() async {
    _jwtToken = await _storage.read(key: 'jwt_token');
    _telegramInitData = await _storage.read(key: 'telegram_init_data');
    dev.log(
      '[Auth] Loaded: JWT=${_jwtToken != null}, Telegram=${_telegramInitData != null}',
      name: 'ApiClient',
    );
  }

  void clearAuth() {
    _telegramInitData = null;
    _jwtToken = null;
    _storage.delete(key: 'jwt_token');
    _storage.delete(key: 'telegram_init_data');
    dev.log('[Auth] Cleared', name: 'ApiClient');
  }

  bool get isAuthenticated => _telegramInitData != null || _jwtToken != null;

  String? get currentToken => _jwtToken;
  String? get currentInitData => _telegramInitData;

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_client._jwtToken != null) {
      options.headers['Authorization'] = 'Bearer ${_client._jwtToken}';
    } else if (_client._telegramInitData != null) {
      options.headers['X-Init-Data'] = _client._telegramInitData;
    }
    dev.log(
      '[Auth] ${options.method} ${options.path} — JWT=${_client._jwtToken != null}, TG=${_client._telegramInitData != null}',
      name: 'ApiClient',
    );
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      '[Auth] ERROR ${err.response?.statusCode} ${err.requestOptions.path}',
      name: 'ApiClient',
    );
    if (err.response?.statusCode == 401) {
      _client.clearAuth();
    }
    handler.next(err);
  }
}
