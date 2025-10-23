import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/auth/session_manager.dart';
import '../../core/errors/exceptions.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionManager sessionManager,
    required RefreshTokenUseCase refreshTokenUseCase,
    required Dio dio,
  })  : _sessionManager = sessionManager,
        _refreshTokenUseCase = refreshTokenUseCase,
        _dio = dio;

  final SessionManager _sessionManager;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final Dio _dio;
  Completer<void>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _sessionManager.session?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isAuthRoute(err.requestOptions)) {
      try {
        await _refreshToken();
        final token = _sessionManager.session?.accessToken;
        if (token != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        handler.reject(err);
        return;
      }
    }
    handler.next(err);
  }

  bool _isAuthRoute(RequestOptions options) {
    return options.path.contains('/auth/login') || options.path.contains('/auth/refresh');
  }

  Future<void> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();
    try {
      final session = _sessionManager.session;
      if (session == null) {
        throw UnauthorizedException();
      }
      final result = await _refreshTokenUseCase.call(
        RefreshTokenParams(refreshToken: session.refreshToken, jti: session.jti),
      );
      await result.fold(
        (failure) => throw UnauthorizedException(),
        (newSession) async {
          await _sessionManager.updateSession(session.copyWith(
            accessToken: newSession.accessToken,
            refreshToken: newSession.refreshToken,
            jti: newSession.jti,
          ));
        },
      );
      _refreshCompleter?.complete();
    } catch (error) {
      _refreshCompleter?.completeError(error);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
