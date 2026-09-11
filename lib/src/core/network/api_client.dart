import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_store.dart';
import 'api_base_url.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (error.response?.statusCode == 401) {
      return 'Invalid username or password.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check the connection and try again.';
    }
  }
  if (error is StateError) {
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}

class ApiClient {
  ApiClient(this._secureStore)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.defaultApiBaseUrl,
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final savedBaseUrl = await _secureStore.readApiBaseUrl();
          final normalizedBaseUrl = normalizeApiBaseUrl(
            savedBaseUrl ?? AppConfig.defaultApiBaseUrl,
          );
          if (normalizedBaseUrl != null) {
            options.baseUrl = normalizedBaseUrl;
          }
          options.path = relativeApiPath(options.path);
          final token = await _secureStore.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SecureStore _secureStore;
  final Dio _dio;

  Dio get dio => _dio;
}
