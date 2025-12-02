import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SplashController extends GetxController {
  @override
  Future<void> onReady() async {
    final config = Get.find<AppConfig>();
    final tokens = Get.find<TokenStorage>();
    final session = Get.find<SessionService>();
    await Future.wait([
      config.load(),
      tokens.load(),
    ]);
    // Reagenda refresh silencioso se já houver sessão
    session.bootstrap();
    // Inicializa monitoramento de conectividade
    await Get.find<ConnectivityService>().init();
    // Inicializa fila offline
    await Get.find<QueueService>().init();
    await Future.delayed(400.milliseconds);

    final rawToken = tokens.accessToken?.trim() ?? '';
    final hasToken = rawToken.isNotEmpty && rawToken.toLowerCase() != 'null';
    final isExpired = hasToken ? JwtDecoder.isExpired(rawToken) : true;
    if (!hasToken || isExpired) {
      await tokens.clear();
      Get.offAndToNamed('/login');
      super.onReady();
      return;
    }

    try {
      final authService = Get.find<AuthService>();
      final authApp = Get.find<AuthServiceApplication>();
      final user =
          await authService.fetchProfile().timeout(const Duration(seconds: 12));
      final isValidUser =
          (user.id).trim().isNotEmpty || (user.email).trim().isNotEmpty;
      if (!isValidUser) {
        await tokens.clear();
        Get.offAndToNamed('/login');
        super.onReady();
        return;
      }
      authApp.user(user);
      session.onLogin(user);
      Get.offAndToNamed('/home');
    } catch (_) {
      await tokens.clear();
      Get.offAndToNamed('/login');
    }
    super.onReady();
  }
}
