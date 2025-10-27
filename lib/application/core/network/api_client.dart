import 'package:dio/dio.dart';

import 'app_config.dart';
import 'token_storage.dart';

class ApiClient {
  final AppConfig _config;
  final TokenStorage _tokens;
  final Dio _dio;

  Dio get dio => _dio;

  ApiClient({required AppConfig config, required TokenStorage tokens})
      : _config = config,
        _tokens = tokens,
        _dio = Dio() {
    _dio.options = BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ensure latest baseUrl and headers
          options.baseUrl = _config.baseUrl;
          // Tenant header não é necessário no login/fluxo atual
          if (_tokens.accessToken != null && _tokens.accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Attempt naive refresh on 401 once
          if (e.response?.statusCode == 401) {
            final retried = e.requestOptions.extra['__ret'] == true;
            final refreshed = await _tryRefreshToken();
            if (!retried && refreshed) {
              final req = e.requestOptions;
              req.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
              req.extra['__ret'] = true;
              try {
                final response = await _dio.fetch(req);
                return handler.resolve(response);
              } catch (err) {
                // fallthrough
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post(
        '/v1/auth/refresh',
        options: Options(
          // Send refresh token as Bearer or body; try Bearer by default
          headers: {
            'Authorization': 'Bearer $refresh',
          },
        ),
      );
      final data = res.data as Map<String, dynamic>;
      final access = (data['accessToken'] ?? '') as String;
      final newRefresh = (data['refreshToken'] ?? refresh) as String;
      final jti = data['jti'] as String?;
      if (access.isNotEmpty) {
        await _tokens.save(access: access, refresh: newRefresh, jti: jti);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
