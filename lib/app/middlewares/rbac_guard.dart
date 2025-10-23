import 'package:get/get.dart';

import '../../core/auth/session_manager.dart';
import '../routes.dart';

class RBACGuard extends GetMiddleware {
  RBACGuard({required this.requiredPermissions});

  final List<String> requiredPermissions;

  @override
  RouteSettings? redirect(String? route) {
    final sessionManager = Get.find<SessionManager>();
    if (!sessionManager.isLogged) {
      return const RouteSettings(name: AppRoutes.login);
    }
    final userPermissions = sessionManager.permissions;
    final hasPermission = requiredPermissions.every(userPermissions.contains);
    if (!hasPermission) {
      Get.snackbar('Permissão insuficiente', 'Você não tem acesso a esta área.');
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
