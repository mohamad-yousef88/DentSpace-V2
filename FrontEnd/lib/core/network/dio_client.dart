import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../services/local_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Configures Dio once for the whole app.
class DioClient {
  DioClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: AppConfig.defaultHeaders,
        responseType: ResponseType.json,
        // Only 2xx is a "success" — anything else throws a DioException
        // that our ErrorInterceptor converts into a typed exception.
        validateStatus: (status) =>
        status != null && status >= 200 && status < 300,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_storage),
      ErrorInterceptor(),
      if (AppConfig.apiBaseUrl.contains('localhost') ||
          AppConfig.apiBaseUrl.contains('10.0.2.2'))
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => Logger().d(obj),
        ),
    ]);
  }

  final LocalStorageService _storage;
  late final Dio _dio;

  Dio get dio => _dio;

  // ─── Convenience methods ─────────────────────────────────
  Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> patch<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) =>
      _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  Future<Response<T>> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

  /// Multipart upload helper.
  Future<Response<T>> upload<T>(
      String path, {
        required FormData formData,
        void Function(int sent, int total)? onSendProgress,
        CancelToken? cancelToken,
      }) =>
      _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(contentType: 'multipart/form-data'),
      );
}