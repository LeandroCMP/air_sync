import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import 'session.dart';
import 'token_storage.dart';

class SessionManager extends GetxService {
  SessionManager(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final _session = Rxn<Session>();

  Session? get session => _session.value;
  bool get isLogged => _session.value != null;
  List<String> get permissions => _tokenStorage.permissions;
  String? get tenantId => _tokenStorage.tenantId;

  Stream<Session?> get changes => _session.stream;

  Future<void> hydrate() async {
    final accessToken = _tokenStorage.accessToken;
    final refreshToken = _tokenStorage.refreshToken;
    final jti = _tokenStorage.jti;
    final tenant = _tokenStorage.tenantId;
    final userMap = _tokenStorage.user;

    if (accessToken == null || refreshToken == null || jti == null || tenant == null || userMap == null) {
      _session.value = null;
      return;
    }

    _session.value = Session(
      userId: userMap['id'] as String? ?? '',
      email: userMap['email'] as String? ?? '',
      name: userMap['name'] as String? ?? '',
      permissions: _tokenStorage.permissions,
      tenantId: tenant,
      accessToken: accessToken,
      refreshToken: refreshToken,
      jti: jti,
    );
  }

  Future<void> updateSession(Session session) async {
    _session.value = session;
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      jti: session.jti,
      tenantId: session.tenantId,
      permissions: session.permissions,
      user: {
        'id': session.userId,
        'email': session.email,
        'name': session.name,
      },
    );
  }

  Future<void> persistRaw(Map<String, dynamic> payload) async {
    await _tokenStorage.saveTokens(
      accessToken: payload['accessToken'] as String,
      refreshToken: payload['refreshToken'] as String,
      jti: payload['jti'] as String,
      tenantId: payload['tenantId'] as String?,
      permissions: (payload['user']?['permissions'] as List<dynamic>? ?? []).cast<String>(),
      user: payload['user'] as Map<String, dynamic>?,
    );
    await hydrate();
  }

  Future<void> clear() async {
    await _tokenStorage.clear();
    _session.value = null;
  }

  Map<String, dynamic>? decodeAccessTokenPayload() {
    final token = _tokenStorage.accessToken;
    if (token == null || token.split('.').length != 3) {
      return null;
    }
    final payload = token.split('.')[1];
    final normalized = base64.normalize(payload);
    final decoded = utf8.decode(base64.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }
}
