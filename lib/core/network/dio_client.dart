import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../app/interceptors/auth_interceptor.dart';
import '../../app/interceptors/logging_interceptor.dart';
import '../../app/interceptors/retry_interceptor.dart';
import '../../app/interceptors/tenant_interceptor.dart';
import '../auth/session_manager.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';

class DioClient {
  DioClient({
    required SessionManager sessionManager,
    required RefreshTokenUseCase refreshTokenUseCase,
  }) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.addAll([
      TenantInterceptor(sessionManager),
      AuthInterceptor(sessionManager: sessionManager, refreshTokenUseCase: refreshTokenUseCase, dio: dio),
      RetryInterceptor(dio: dio),
      if (kDebugMode) LoggingInterceptor(),
    ]);

    _dio = dio;
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
