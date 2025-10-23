import 'package:get/get.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/auth/session_manager.dart';

class SessionController extends GetxController {
  SessionController(this._sessionManager);

  final SessionManager _sessionManager;

  final session = Rxn<Session>();

  @override
  void onInit() {
    super.onInit();
    session.value = _sessionManager.session;
    _sessionManager.changes.listen((event) => session.value = event);
  }

  Future<void> logout() async {
    await _sessionManager.clear();
  }
}
