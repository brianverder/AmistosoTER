import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/constants.dart';

/// Excepción tipada para errores de API
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP centralizado que wrappea Dio.
/// Maneja: cookies (sesión), headers comunes, y mapeo de errores.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        extra: {'withCredentials': true},
      ),
    );

    // En Flutter Web, forzar withCredentials para que el browser envíe
    // las cookies de sesión (next-auth) en todas las peticiones cross-origin.
    if (kIsWeb) {
      // Configurar el adaptador de browser para siempre enviar credenciales
      _dio.options.extra['withCredentials'] = true;
    }

    // Interceptor: asegura withCredentials en cada petición (Flutter Web)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Forzar withCredentials para que las cookies de sesión se envíen
          options.extra['withCredentials'] = true;
          assert(() {
            // ignore: avoid_print
            print('[API] ${options.method} ${options.path}');
            return true;
          }());
          return handler.next(options);
        },
        onError: (error, handler) {
          assert(() {
            // ignore: avoid_print
            print('[API ERROR] ${error.response?.statusCode}: ${error.message} — ${error.response?.data}');
            return true;
          }());
          return handler.next(error);
        },
      ),
    );
  }

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(path, data: data, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(path, data: data, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path, {Options? options}) async {
    try {
      await _dio.delete(path, options: options);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Envío de formulario (usado para NextAuth callback) ───────────────────

  Future<Response<dynamic>> postForm(
    String path,
    Map<String, String> formFields,
  ) async {
    try {
      return await _dio.post(
        path,
        data: formFields.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
          extra: {'withCredentials': true},
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Mapeo de errores ─────────────────────────────────────────────────────

  ApiException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
          message: 'Tiempo de conexión agotado', statusCode: 408);
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
          message: 'Sin conexión a internet', statusCode: 0);
    }

    final statusCode = e.response?.statusCode ?? 500;
    String message = 'Error del servidor';

    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['error'] as String? ??
            data['message'] as String? ??
            message;
      } else if (data is String && data.isNotEmpty) {
        // Intentar parsear JSON si es string
        try {
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          message = parsed['error'] as String? ?? message;
        } catch (_) {
          // data es plain text
        }
      }
    } catch (_) {}

    return ApiException(message: message, statusCode: statusCode);
  }
}
