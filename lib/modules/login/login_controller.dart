import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/errors/auth_failure.dart';
import 'package:air_sync/application/core/services/local_storage_service.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
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

  RxBool viewPassword = true.obs;
  RxBool saveUserVar = false.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
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
    if (emailController.text.isNotEmpty && emailController.text.isEmail) {
      saveUserVar.value = value ?? false;
      _storage.setRememberMe(saveUserVar.value);
      _storage.setEmail(saveUserVar.value == true ? emailController.text : '');
    }
  }

  Future<void> login() async {
    try {
      isLoading.value = true;
      final user = await _authService.auth(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      _authServiceApplication.user(user);
      Get.offAllNamed('/home');
      isLoading.value = false;
    } on AuthFailure catch (e) {
      isLoading.value = false;
      message(
        MessageModel.error(title: 'Erro ao fazer login', message: e.message),
      );
    } catch (_) {
      isLoading.value = false;
      message(
        MessageModel.error(
          title: 'Erro inesperado',
          message: 'Ocorreu um erro inesperado. Tente novamente mais tarde!',
        ),
      );
    }
  }

  Future<void> resetPassword(String email) async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.isEmail) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Informe um e-mail válido para redefinir a senha.',
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(email);
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'E-mail de redefinição de senha enviado.',
        ),
      );
    } on AuthFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Erro inesperado. Tente novamente mais tarde.',
        ),
      );
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _authServiceApplication.user.value = null;
      passwordController.clear();
      Get.offAllNamed('/login');
    } catch (e) {
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
