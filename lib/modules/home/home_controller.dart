import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final AuthServiceApplication _authServiceApplication;
  final AuthService _authService;

  HomeController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
  }) : _authService = authService,
       _authServiceApplication = authServiceApplication;

  final Rxn<UserModel> user = Rxn<UserModel>();

  @override
  void onInit() {
    user(_authServiceApplication.user.value);
    super.onInit();
  }
}
