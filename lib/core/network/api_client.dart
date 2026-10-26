import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    SecureTokenStorage? tokenStorage,
  })  : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Content-Type': 'application/json'},
            )) {
    this.dio.interceptors.add(_AuthInterceptor(_tokenStorage, this.dio));
  }

  final Dio dio;
  final SecureTokenStorage _tokenStorage;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);

  final SecureTokenStorage _storage;
  final Dio _dio;
  bool _refreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path == '/auth/refresh' ||
        _refreshing) {
      handler.next(err);
      return;
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      handler.next(err);
      return;
    }

    _refreshing = true;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuthRefresh': true}),
      );
      final accessToken = response.data?['access_token'] as String?;
      final newRefreshToken = response.data?['refresh_token'] as String?;
      if (accessToken == null) {
        handler.next(err);
        return;
      }
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );
      final retry = await _dio.fetch<dynamic>(
        err.requestOptions
          ..headers['Authorization'] = 'Bearer $accessToken',
      );
      handler.resolve(retry);
    } on DioException {
      await _storage.clear();
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
