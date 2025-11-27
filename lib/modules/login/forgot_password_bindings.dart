import 'package:air_sync/modules/login/forgot_password_controller.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';

class ForgotPasswordBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ForgotPasswordController(authService: Get.find<AuthService>()),
    );
  }
}
