import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';

/// Clé [RequestOptions.extra] pour éviter une boucle infinie de retry 401.
const String _authRetryKey = 'auth_retry';

final dioProvider = Provider<Dio>((ref) {
  final AuthService authService = ref.watch(authServiceProvider);
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(authService, dio));
  return dio;
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._authService, this._dio);

  final AuthService _authService;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final String token = await _authService.getValidToken();
      options.headers['Authorization'] = 'Bearer $token';
    } on AuthException {
      // Pas de session valide : la requête part sans token et sera rejetée
      // en 401 par le backend. Le retry onError tentera un refresh forcé.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final bool isUnauthorized = err.response?.statusCode == 401;
    final bool alreadyRetried = err.requestOptions.extra[_authRetryKey] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final String token =
          await _authService.getValidToken(forceRefresh: true);
      final RequestOptions requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $token';
      requestOptions.extra[_authRetryKey] = true;

      final Response<dynamic> response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } on AuthException {
      handler.next(err);
    } catch (_) {
      handler.next(err);
    }
  }
}
