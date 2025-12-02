import 'package:air_sync/application/core/errors/auth_failure.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/repositories/auth/auth_repository.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:get/get.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api = Get.find<ApiClient>();
  final TokenStorage _tokens = Get.find<TokenStorage>();
  final AppConfig _config = Get.find<AppConfig>();

  UserModel _mapUser(
    Map<String, dynamic> userData, {
    String? fallbackEmail,
  }) {
    final id = (userData['id'] ?? userData['_id'] ?? '').toString();
    if (id.isEmpty) {
      throw const AuthFailure(
        AuthFailureType.userNotFound,
        'Usuário inválido retornado pela API.',
      );
    }
    final email = (userData['email'] ?? fallbackEmail ?? '').toString();
    final role = (userData['role'] ?? '').toString();
    final permissions =
        ((userData['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
    final mustChangePassword =
        userData['mustChangePassword'] == true ||
        userData['must_change_password'] == true;

    return UserModel(
      id: id,
      name: (userData['name'] ?? userData['fullName'] ?? '').toString(),
      email: email,
      phone: userData['phone']?.toString() ?? '',
      dateBorn: null,
      userLevel: 0,
      planExpiration: null,
      cpfOrCnpj: userData['document']?.toString() ?? '',
      role: role,
      permissions: permissions,
      mustChangePassword: mustChangePassword,
    );
  }

  @override
  Future<UserModel> auth(String email, String password) async {
    try {
      final res = await _api.dio.post(
        '/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final access = (data['accessToken'] ?? '') as String;
      final refresh = (data['refreshToken'] ?? '') as String;
      final jti = data['jti'] as String?;
      await _tokens.save(access: access, refresh: refresh, jti: jti);
      _updateTenantId(data);

      final userData =
          Map<String, dynamic>.from(
            (data['user'] ?? data['account'] ?? <String, dynamic>{})
                as Map,
          );
      _updateTenantId(userData);
      userData['email'] ??= email;
      return _mapUser(userData, fallbackEmail: email);
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
  Future<UserModel> me() async {
    final res = await _api.dio.get('/v1/auth/me');
    final data = Map<String, dynamic>.from((res.data ?? {}) as Map);
    _updateTenantId(data);
    return _mapUser(data);
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? document,
  }) async {
    final payload = <String, dynamic>{};
    String? sanitizeDigits(String? value) {
      if (value == null) return null;
      final digits = value.replaceAll(RegExp(r'\\D'), '');
      return digits.isEmpty ? null : digits;
    }

    if (name != null && name.trim().isNotEmpty) payload['name'] = name.trim();
    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    final sanitizedPhone = sanitizeDigits(phone);
    if (sanitizedPhone != null) payload['phone'] = sanitizedPhone;
    final sanitizedDocument = sanitizeDigits(document);
    if (sanitizedDocument != null) payload['document'] = sanitizedDocument;
    final res = await _api.dio.patch('/v1/auth/me', data: payload);
    final data = res.data;
    if (data is Map) {
      return _mapUser(Map<String, dynamic>.from(data));
    }
    // fallback: reconsultar
    return me();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.dio.post(
      '/v1/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _api.dio.post('/v1/auth/forgot-password', data: {'email': email});
    } catch (_) {
      // evita revelar se o e-mail existe ou não
    }
  }

  @override
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    await _api.dio.post(
      '/v1/auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
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

  void _updateTenantId(Map<dynamic, dynamic> source) {
    String? resolve(dynamic value) {
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) return value;
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final nested = map['id'] ?? map['_id'] ?? map['tenantId'];
        if (nested is String && nested.trim().isNotEmpty) return nested;
      }
      return null;
    }

    final candidate = resolve(source['tenantId']) ??
        resolve(source['tenant_id']) ??
        resolve(source['tenant']) ??
        resolve(source['account']?['tenant']) ??
        resolve(source['user']?['tenant']);

    if (candidate != null && candidate != _config.tenantId) {
      unawaited(_config.setTenantId(candidate));
    }
  }
}
