import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login(String email, String password, {String? tenantId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(headers: tenantId != null ? {'X-Tenant-Id': tenantId} : null),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> refresh(String refreshToken, String jti) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {
        'refreshToken': refreshToken,
        'jti': jti,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> logout() async {
    await _dio.post('/v1/auth/logout');
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/auth/me');
    return response.data ?? <String, dynamic>{};
  }
}
