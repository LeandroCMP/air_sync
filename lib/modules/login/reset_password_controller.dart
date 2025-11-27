import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController
    with LoaderMixin, MessagesMixin {
  ResetPasswordController({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    tokenController.text =
        (Get.arguments as String?) ??
        Get.parameters['token'] ??
        '';
    super.onInit();
  }

  Future<void> submit() async {
    final token = tokenController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (token.isEmpty) {
      message(
        MessageModel.error(
          title: 'Token obrigatório',
          message: 'Cole o token recebido por e-mail para continuar.',
        ),
      );
      return;
    }
    if (newPassword.length < 8) {
      message(
        MessageModel.error(
          title: 'Senha fraca',
          message: 'A nova senha deve ter pelo menos 8 caracteres.',
        ),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      message(
        MessageModel.error(
          title: 'Confirmação inválida',
          message: 'As senhas informadas não conferem.',
        ),
      );
      return;
    }

    isLoading.value = true;
    try {
      // POST /v1/auth/reset-password
      await _authService.resetPasswordWithToken(
        token: token,
        newPassword: newPassword,
      );
      message(
        MessageModel.success(
          title: 'Senha redefinida',
          message: 'Entre novamente com sua nova senha.',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed('/login');
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Falha ao redefinir',
          message: error.toString(),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
