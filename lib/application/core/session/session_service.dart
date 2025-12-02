import 'dart:async';

import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionService extends GetxService {
  final TokenStorage _tokens;
  final ApiClient _apiClient;

  Timer? _refreshTimer;
  bool _handlingForcedLogout = false;

  SessionService({
    required TokenStorage tokens,
    required ApiClient apiClient,
  })  : _tokens = tokens,
        _apiClient = apiClient {
    _apiClient.addLogoutCallback(_handleForcedLogout);
  }

  void onLogin(UserModel user) {
    _scheduleSilentRefresh();
  }

  void bootstrap() {
    // chamado no Splash para reagendar ao abrir o app
    if (_tokens.accessToken != null && _tokens.accessToken!.isNotEmpty) {
      _scheduleSilentRefresh();
    }
  }

  void cancel() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _scheduleSilentRefresh() {
    cancel();
    final access = _tokens.accessToken;
    if (access == null || access.isEmpty) return;
    try {
      final expDate = JwtDecoder.getExpirationDate(access);
      final now = DateTime.now();
      final diff = expDate.difference(now);
      final fireIn = diff - const Duration(seconds: 60);
      final duration = fireIn.isNegative ? const Duration(seconds: 10) : fireIn;
      _refreshTimer = Timer(duration, _silentRefresh);
    } catch (_) {
      // Se token inválido, tenta refresh curto
      _refreshTimer = Timer(const Duration(seconds: 10), _silentRefresh);
    }
  }

  Future<void> _silentRefresh() async {
    // Atualiza o token de forma proativa para evitar redirecionamento tardio
    try {
      final refresh = _tokens.refreshToken;
      if (refresh == null || refresh.isEmpty) {
        _handleForcedLogout();
        return;
      }
      final res = await _apiClient.dio.post(
        '/v1/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final raw = res.data;
      final data =
          raw is Map<String, dynamic>
              ? raw
              : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      final access = (data['accessToken'] ?? '').toString();
      final newRefresh = (data['refreshToken'] ?? refresh).toString();
      final jti = data['jti']?.toString();
      if (access.isEmpty) {
        _handleForcedLogout();
        return;
      }
      await _tokens.save(access: access, refresh: newRefresh, jti: jti);
    } catch (_) {
      _handleForcedLogout();
    } finally {
      _scheduleSilentRefresh();
    }
  }

  void _handleForcedLogout() {
    if (_handlingForcedLogout) return;
    _handlingForcedLogout = true;
    cancel();
    unawaited(_tokens.clear());
    if (Get.isRegistered<AuthServiceApplication>()) {
      Get.find<AuthServiceApplication>().user.value = null;
    }
    Get.offAllNamed('/login');
  }
}
