import 'package:get/get.dart';

import '../../../../core/auth/session_manager.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/usecases/login_usecase.dart';

class LoginController extends GetxController {
  LoginController(this._loginUseCase, this._sessionManager);

  final LoginUseCase _loginUseCase;
  final SessionManager _sessionManager;

  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  Future<bool> submit({String? tenantId}) async {
    isLoading.value = true;
    errorMessage.value = null;
    final result = await _loginUseCase.call(LoginParams(email: email.value, password: password.value, tenantId: tenantId));
    isLoading.value = false;
    return result.fold(
      (failure) {
        errorMessage.value = _mapFailure(failure);
        return false;
      },
      (session) {
        _sessionManager.updateSession(session);
        return true;
      },
    );
  }

  String _mapFailure(Failure failure) => failure.message;
}
