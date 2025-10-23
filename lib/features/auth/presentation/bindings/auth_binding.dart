import 'package:get/get.dart';

import '../../../../core/auth/session_manager.dart';
import '../../domain/usecases/login_usecase.dart';
import '../controllers/login_controller.dart';
import '../controllers/session_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController(Get.find<LoginUseCase>(), Get.find<SessionManager>()));
    Get.put(SessionController(Get.find<SessionManager>()), permanent: true);
  }
}
