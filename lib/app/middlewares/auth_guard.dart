import 'package:get/get.dart';

import '../../core/auth/session_manager.dart';
import '../routes.dart';

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final sessionManager = Get.find<SessionManager>();
    if (!sessionManager.isLogged) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}
