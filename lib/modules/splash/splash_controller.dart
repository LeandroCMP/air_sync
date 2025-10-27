import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  Future<void> onReady() async {
    final config = Get.find<AppConfig>();
    final tokens = Get.find<TokenStorage>();
    await Future.wait([
      config.load(),
      tokens.load(),
    ]);
    // Reagenda refresh silencioso se já houver sessão
    Get.find<SessionService>().bootstrap();
    // Inicializa monitoramento de conectividade
    await Get.find<ConnectivityService>().init();
    // Inicializa fila offline
    await Get.find<QueueService>().init();
    await Future.delayed(800.milliseconds);
    Get.offAndToNamed('/login');
    super.onReady();
  }
}
