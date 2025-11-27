import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeTempPasswordController extends GetxController
    with LoaderMixin, MessagesMixin {
  ChangeTempPasswordController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
  })  : _authService = authService,
        _authApp = authServiceApplication;

  final AuthService _authService;
  final AuthServiceApplication _authApp;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final hideNewPassword = true.obs;
  final hideConfirmPassword = true.obs;

  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;

  String _tempPassword = '';

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    final args = Get.arguments;
    if (args is Map && args['tempPassword'] is String) {
      _tempPassword = args['tempPassword'] as String;
    }
    super.onInit();
  }

  Future<void> submit() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    if (newPassword.length < 6) {
      message(
        MessageModel.error(
          title: 'Senha inválida',
          message: 'Use ao menos 6 caracteres.',
        ),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      message(
        MessageModel.error(
          title: 'Senhas não conferem',
          message: 'Repita a nova senha corretamente.',
        ),
      );
      return;
    }
    isLoading.value = true;
    try {
      await _authService.changePassword(
        currentPassword: _tempPassword,
        newPassword: newPassword,
      );
      final currentUser = _authApp.user.value;
      if (currentUser != null) {
        _authApp.user(currentUser.copyWith(mustChangePassword: false));
      }
      message(
        MessageModel.success(
          title: 'Senha atualizada',
          message: 'Agora você pode acessar o sistema normalmente.',
        ),
      );
      Get.offAllNamed('/home');
    } on Exception catch (e) {
      message(
        MessageModel.error(
          title: 'Erro ao atualizar senha',
          message: e.toString(),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
