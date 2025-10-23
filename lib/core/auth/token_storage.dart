import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class TokenStorage {
  TokenStorage(this._box);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _jtiKey = 'jti';
  static const _tenantKey = 'tenant_id';
  static const _permissionsKey = 'permissions';
  static const _userKey = 'user';

  final GetStorage _box;

  String? get accessToken => _box.read<String?>(_accessTokenKey);

  String? get refreshToken => _box.read<String?>(_refreshTokenKey);

  String? get jti => _box.read<String?>(_jtiKey);

  String? get tenantId => _box.read<String?>(_tenantKey);

  List<String> get permissions {
    final value = _box.read<String?>(_permissionsKey);
    if (value == null) {
      return [];
    }
    return (jsonDecode(value) as List<dynamic>).cast<String>();
  }

  Map<String, dynamic>? get user {
    final value = _box.read<String?>(_userKey);
    if (value == null) {
      return null;
    }
    return jsonDecode(value) as Map<String, dynamic>;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String jti,
    String? tenantId,
    List<String>? permissions,
    Map<String, dynamic>? user,
  }) async {
    await _box.write(_accessTokenKey, accessToken);
    await _box.write(_refreshTokenKey, refreshToken);
    await _box.write(_jtiKey, jti);
    if (tenantId != null) {
      await _box.write(_tenantKey, tenantId);
    }
    if (permissions != null) {
      await _box.write(_permissionsKey, jsonEncode(permissions));
    }
    if (user != null) {
      await _box.write(_userKey, jsonEncode(user));
    }
  }

  Future<void> saveTenant(String tenantId) => _box.write(_tenantKey, tenantId);

  Future<void> clear() async {
    await _box.remove(_accessTokenKey);
    await _box.remove(_refreshTokenKey);
    await _box.remove(_jtiKey);
    await _box.remove(_tenantKey);
    await _box.remove(_permissionsKey);
    await _box.remove(_userKey);
  }
}
