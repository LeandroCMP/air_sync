import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/errors/auth_failure.dart';
import 'package:air_sync/application/core/services/local_storage_service.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController with MessagesMixin, LoaderMixin {
  final AuthServiceApplication _authServiceApplication;
  final AuthService _authService;

  LoginController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
  }) : _authService = authService,
       _authServiceApplication = authServiceApplication;

  final _storage = LocalStorageService();

  // UI states
  final viewPassword = true.obs;
  final saveUserVar = false.obs;
  final isLoading = false.obs;

  // Form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final message = Rxn<MessageModel>();

  @override
  void onInit() {
    _loadRememberMe();
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  Future<void> _loadRememberMe() async {
    saveUserVar.value = await _storage.getRememberMe();
    emailController.text = await _storage.getEmail();
  }

  void toggleRememberMe(bool? value) {
    // Alterna o switch; persiste "lembrar" e o e-mail apenas se válido.
    saveUserVar.value = value ?? false;
    _storage.setRememberMe(saveUserVar.value);
    if (emailController.text.isEmail) {
      _storage.setEmail(saveUserVar.value ? emailController.text : '');
    } else {
      _storage.setEmail('');
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.isEmail) {
      message(
        MessageModel.error(
          title: 'E-mail inválido',
          message: 'Informe um e-mail válido.',
        ),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      message(
        MessageModel.error(
          title: 'Senha inválida',
          message: 'Informe sua senha (mínimo de 6 caracteres).',
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      final user = await _authService
          .auth(email, password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw AuthFailure(
                AuthFailureType.timeout,
                AuthFailure.messageForType(AuthFailureType.timeout),
              );
            },
          );

      if (saveUserVar.value) {
        await _storage.setRememberMe(true);
        await _storage.setEmail(email);
      } else {
        await _storage.setRememberMe(false);
        await _storage.setEmail('');
      }

      _authServiceApplication.user(user);
      Get.find<SessionService>().onLogin(user);

      message(
        MessageModel.success(
          title: 'Tudo certo',
          message: 'Sessão iniciada com sucesso.',
        ),
      );

      Get.offAllNamed('/home');
    } on AuthFailure catch (e) {
      message(
        MessageModel.error(title: 'Erro ao fazer login', message: e.message),
      );
    } on Exception catch (e) {
      final failure = AuthFailure.fromException(e);
      message(
        MessageModel.error(
          title: 'Erro ao fazer login',
          message: failure.message,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    final target = email.trim();

    if (target.isEmpty || !target.isEmail) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Informe um e-mail válido para redefinir a senha.',
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(target);
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'E-mail de redefinição de senha enviado.',
        ),
      );
    } on AuthFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } on Exception catch (e) {
      final failure = AuthFailure.fromException(e);
      message(MessageModel.error(title: 'Erro', message: failure.message));
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _authServiceApplication.user.value = null;
      passwordController.clear();
      Get.offAllNamed('/login');
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro ao sair',
          message: 'Não foi possível fazer logout. Tente novamente!',
        ),
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
