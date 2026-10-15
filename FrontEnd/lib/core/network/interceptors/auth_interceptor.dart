import 'package:dio/dio.dart';

import '../../services/local_storage_service.dart';

/// Attaches the Bearer token to every request (except auth endpoints),
/// and clears the token on a hard 401 (the caller decides what to do next).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final LocalStorageService _storage;

  static const _authWhitelist = [
    '/auth/login',
    '/auth/register',
    '/auth/verify-email',
    '/auth/resend-otp',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  bool _isWhitelisted(String path) =>
      _authWhitelist.any((route) => path.contains(route));

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    if (!_isWhitelisted(options.path)) {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final status = err.response?.statusCode;
    if (status == 401 && !_isWhitelisted(err.requestOptions.path)) {
      // Refresh attempt could be added here in a later batch.
      // For now we simply clear the token; the app will redirect to login.
      await _storage.clearAuth();
    }
    handler.next(err);
  }
}