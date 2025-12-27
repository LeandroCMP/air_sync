import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/network/token_storage.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/application/core/sync/sync_service.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  HomeController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
  })  : _authService = authService,
        _authServiceApplication = authServiceApplication;

  final AuthServiceApplication _authServiceApplication;
  final AuthService _authService;
  final SessionService _sessionService = Get.find<SessionService>();
  final SyncService _syncService = Get.find<SyncService>();

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
    _guardAuthenticated();
    _syncService.syncInitial();
    super.onReady();
  }

  void setIndex(int i) => currentIndex.value = i;

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      Get.snackbar(
        'Erro ao sair',
        'Não foi possível concluir o logout. Tente novamente.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } finally {
      _sessionService.cancel();
      _authServiceApplication.user.value = null;
      if (Get.isRegistered<TokenStorage>()) {
        await Get.find<TokenStorage>().clear();
      }
    }
    Get.offAllNamed('/login');
  }

  Future<void> _guardAuthenticated() async {
    final current = _authServiceApplication.user.value;
    final hasUser =
        current != null && ((current.id).trim().isNotEmpty || current.email.trim().isNotEmpty);
    if (hasUser) return;
    _sessionService.cancel();
    if (Get.isRegistered<TokenStorage>()) {
      await Get.find<TokenStorage>().clear();
    }
    _authServiceApplication.user.value = null;
    Get.offAllNamed('/login');
  }
}
