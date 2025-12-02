import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_config.dart';
import 'token_storage.dart';

class ApiClient {
  final AppConfig _config;
  final TokenStorage _tokens;
  final Dio _dio;

  final _logoutCallbacks = <VoidCallback>{};

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
          // X-Tenant-Id (quando disponível)
          if (_config.tenantId.isNotEmpty) {
            options.headers['X-Tenant-Id'] = _config.tenantId;
          }
          // Não sobrescrever Authorization em /auth/refresh
          final path = options.path;
          final isRefresh = path.contains('/auth/refresh');
          if (!isRefresh && _tokens.accessToken != null && _tokens.accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Attempt naive refresh on 401 once
          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            final isRefresh = path.contains('/auth/refresh');
            if (isRefresh) {
              await _handleRefreshFailure();
            } else {
              final retried = e.requestOptions.extra['__ret'] == true;
              final refreshed = await _tryRefreshToken();
              if (!retried && refreshed) {
                final req = e.requestOptions;
                req.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
                req.extra['__ret'] = true;
                try {
                  final response = await _dio.request<dynamic>(
                    req.path,
                    data: req.data,
                    queryParameters: req.queryParameters,
                    options: Options(
                      method: req.method,
                      headers: req.headers,
                      contentType: req.contentType,
                      responseType: req.responseType,
                      followRedirects: req.followRedirects,
                      validateStatus: req.validateStatus,
                      receiveDataWhenStatusError: req.receiveDataWhenStatusError,
                      sendTimeout: req.sendTimeout,
                      receiveTimeout: req.receiveTimeout,
                      extra: req.extra,
                    ),
                    cancelToken: req.cancelToken,
                    onReceiveProgress: req.onReceiveProgress,
                    onSendProgress: req.onSendProgress,
                  );
                  return handler.resolve(response);
                } catch (err) {
                  // fallthrough
                }
              } else if (!refreshed) {
                await _handleRefreshFailure();
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  void addLogoutCallback(VoidCallback callback) {
    _logoutCallbacks.add(callback);
  }

  void removeLogoutCallback(VoidCallback callback) {
    _logoutCallbacks.remove(callback);
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = _tokens.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post(
        '/v1/auth/refresh',
        data: {
          'refreshToken': refresh,
        },
        options: Options(headers: {
          if (_config.tenantId.isNotEmpty) 'X-Tenant-Id': _config.tenantId,
        }),
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

  Future<void> _handleRefreshFailure() async {
    await _tokens.clear();
    for (final callback in _logoutCallbacks) {
      try {
        callback();
      } catch (_) {
        // ignore
      }
    }
  }
}
