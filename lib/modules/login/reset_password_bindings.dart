import 'package:air_sync/modules/login/reset_password_controller.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';

class ResetPasswordBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ResetPasswordController(authService: Get.find<AuthService>()),
    );
  }
}
