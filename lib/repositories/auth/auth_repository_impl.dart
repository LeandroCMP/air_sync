import 'package:air_sync/application/core/errors/auth_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/repositories/auth/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api = Get.find<ApiClient>();
  final TokenStorage _tokens = Get.find<TokenStorage>();

  @override
  Future<UserModel> auth(String email, String password) async {
    try {
      final res = await _api.dio.post(
        '/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      final access = (data['accessToken'] ?? '') as String;
      final refresh = (data['refreshToken'] ?? '') as String;
      final jti = data['jti'] as String?;
      await _tokens.save(access: access, refresh: refresh, jti: jti);

      final userData =
          (data['user'] ?? data['account'] ?? {}) as Map<String, dynamic>;
      final id = (userData['id'] ?? userData['_id'] ?? '').toString();
      final name = (userData['name'] ?? userData['fullName'] ?? '').toString();
      final emailResp = (userData['email'] ?? email).toString();
      final role = (userData['role'] ?? '').toString();
      final permissions =
          ((userData['permissions'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList();

      if (id.isEmpty) {
        throw const AuthFailure(
          AuthFailureType.userNotFound,
          'Usuário inválido retornado pela API.',
        );
      }

      return UserModel(
        id: id,
        name: name,
        email: emailResp,
        phone: userData['phone']?.toString() ?? '',
        dateBorn: null,
        userLevel: 0,
        planExpiration: null,
        cpfOrCnpj: userData['document']?.toString() ?? '',
        role: role,
        permissions: permissions,
      );
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401) {
        throw const AuthFailure(
          AuthFailureType.wrongPassword,
          'Usuário ou senha inválidos.',
        );
      }
      throw const AuthFailure(
        AuthFailureType.unknown,
        'Erro de autenticação com a API.',
      );
    } catch (_) {
      throw const AuthFailure(AuthFailureType.unknown, 'Erro inesperado.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    // Opcional: implementar quando a API disponibilizar a rota específica
    try {
      await _api.dio.post('/v1/auth/forgot-password', data: {'email': email});
    } catch (_) {
      // Ignora falhas, mantém UX consistente
    }
  }

  @override
  Future<void> logout() async {
    try {
      final jti = _tokens.jti;
      if (jti != null && jti.isNotEmpty) {
        await _api.dio.post('/v1/auth/logout', data: {'jti': jti});
      }
    } catch (_) {
      // Ignora erro de logout remoto
    } finally {
      await _tokens.clear();
    }
  }
}
