import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/application/core/sync/sync_service.dart';
import 'package:air_sync/application/core/queue/queue_service.dart';
import 'package:air_sync/repositories/finance/finance_repository.dart';
import 'package:air_sync/repositories/finance/finance_repository_impl.dart';
import 'package:air_sync/services/finance/finance_service.dart';
import 'package:air_sync/services/finance/finance_service_impl.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/modules/splash/splash_controller.dart';
import 'package:air_sync/repositories/auth/auth_repository.dart';
import 'package:air_sync/repositories/auth/auth_repository_impl.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:air_sync/services/auth/auth_service.impl.dart';
import 'package:get/get.dart';

class ApplicationBindings implements Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
    // Core config + HTTP
    Get.put(AppConfig(), permanent: true);
    Get.put(TokenStorage(), permanent: true);
    Get.put(ApiClient(config: Get.find(), tokens: Get.find()), permanent: true);
    Get.put(SyncService(), permanent: true);
    // Registra o serviço de conectividade de forma síncrona
    Get.put(ConnectivityService(), permanent: true);
    Get.put(QueueService(), permanent: true);
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(), fenix: true);
    Get.lazyPut<AuthService>(
      () => AuthServiceImpl(authRepository: Get.find()),
      fenix: true,
    );
    Get.lazyPut<FinanceRepository>(() => FinanceRepositoryImpl(), fenix: true);
    Get.lazyPut<FinanceService>(() => FinanceServiceImpl(repo: Get.find()), fenix: true);
    Get.put(SessionService(tokens: Get.find(), authService: Get.find()), permanent: true);
    Get.put(AuthServiceApplication(user: Rxn<UserModel>()));
  }
}
