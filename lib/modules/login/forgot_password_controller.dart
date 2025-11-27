import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController
    with LoaderMixin, MessagesMixin {
  ForgotPasswordController({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  final emailController = TextEditingController();
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    final initialEmail = Get.arguments as String?;
    if ((initialEmail ?? '').isEmail) {
      emailController.text = initialEmail!;
    }
    super.onInit();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    if (!email.isEmail) {
      message(
        MessageModel.error(
          title: 'E-mail inválido',
          message: 'Informe um e-mail válido para receber o link.',
        ),
      );
      return;
    }
    isLoading.value = true;
    try {
      // POST /v1/auth/forgot-password
      await _authService.requestPasswordReset(email);
      message(
        MessageModel.success(
          title: 'Verifique sua caixa de entrada',
          message:
              'Se encontrarmos uma conta para $email enviaremos instruções de redefinição.',
        ),
      );
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Falha ao solicitar redefinição',
          message: error.toString(),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
