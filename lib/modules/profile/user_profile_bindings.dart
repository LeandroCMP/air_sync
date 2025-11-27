import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/modules/profile/user_profile_controller.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';

class UserProfileBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => UserProfileController(
        authService: Get.find<AuthService>(),
        authServiceApplication: Get.find<AuthServiceApplication>(),
        sessionService: Get.find<SessionService>(),
      ),
    );
  }
}
