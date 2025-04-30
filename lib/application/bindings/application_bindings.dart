import 'package:air_sync/application/auth/auth_service_application.dart';
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
    Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(), fenix: true);
    Get.lazyPut<AuthService>(
      () => AuthServiceImpl(authRepository: Get.find()),
      fenix: true,
    );
    Get.put(AuthServiceApplication(user: Rxn<UserModel>()));
  }
}
