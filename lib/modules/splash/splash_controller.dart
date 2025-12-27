import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_bindings.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_controller.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_page.dart';
import 'package:air_sync/application/core/services/local_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SplashController extends GetxController {
  @override
  Future<void> onReady() async {
    final config = Get.find<AppConfig>();
    final tokens = Get.find<TokenStorage>();
    final session = Get.find<SessionService>();
    final storage = LocalStorageService();
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
      // se já sabemos que está suspenso, força billing antes de fetch
      final suspendedFlag = await storage.isSuspendedFlag();
      if (suspendedFlag) {
        if (!Get.isRegistered<SubscriptionsController>()) {
          SubscriptionsBindings().dependencies();
        }
        Get.offAll(
          () => const SubscriptionsPage(),
          binding: SubscriptionsBindings(),
          arguments: {
            'restricted': true,
            'reason': 'ACCOUNT_SUSPENDED',
          },
        );
        super.onReady();
        return;
      }
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
    } on DioException catch (e) {
      final code = _errorCode(e);
      if (code == 'ACCOUNT_SUSPENDED') {
        await storage.setSuspendedFlag(true);
        if (!Get.isRegistered<SubscriptionsController>()) {
          SubscriptionsBindings().dependencies();
        }
        Get.offAll(
          () => const SubscriptionsPage(),
          binding: SubscriptionsBindings(),
          arguments: {
            'restricted': true,
            'reason': code,
          },
        );
        super.onReady();
        return;
      }
      await tokens.clear();
      Get.offAndToNamed('/login');
    } catch (_) {
      await tokens.clear();
      Get.offAndToNamed('/login');
    }
    super.onReady();
  }

  String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['code'] is String) {
        final code = (nested['code'] as String).trim();
        if (code.isNotEmpty) return code;
      }
      if (data['code'] is String) {
        final code = (data['code'] as String).trim();
        if (code.isNotEmpty) return code;
      }
    }
    return null;
  }
}
