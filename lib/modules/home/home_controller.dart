import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/sync/sync_service.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final AuthServiceApplication _authServiceApplication;
  final SyncService _syncService = Get.find<SyncService>();

  HomeController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
  }) : _authServiceApplication = authServiceApplication;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxInt currentIndex = 0.obs;
  RxBool get isSyncing => _syncService.isSyncing;

  @override
  void onInit() {
    user(_authServiceApplication.user.value);
    super.onInit();
  }

  @override
  void onReady() {
    // dispara sync inicial rápido
    _syncService.syncInitial();
    super.onReady();
  }

  void setIndex(int i) => currentIndex.value = i;
}
