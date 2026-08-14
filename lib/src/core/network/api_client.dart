import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_store.dart';

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
          if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
            options.baseUrl = savedBaseUrl;
          }
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
