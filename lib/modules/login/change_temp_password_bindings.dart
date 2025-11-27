import 'package:air_sync/modules/login/change_temp_password_controller.dart';
import 'package:get/get.dart';

class ChangeTempPasswordBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ChangeTempPasswordController(
        authService: Get.find(),
        authServiceApplication: Get.find(),
      ),
    );
  }
}
