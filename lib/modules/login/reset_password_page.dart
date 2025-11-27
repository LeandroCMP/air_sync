import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/modules/login/reset_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordPage extends GetView<ResetPasswordController> {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir senha'),
        backgroundColor: context.themeDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informe o token recebido e defina uma nova senha segura.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.tokenController,
                decoration: const InputDecoration(
                  labelText: 'Token',
                  hintText: 'Cole o token enviado por e-mail',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  helperText: 'Mínimo de 8 caracteres',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nova senha',
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_reset),
                    onPressed:
                        controller.isLoading.value ? null : controller.submit,
                    label: controller.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Atualizar senha'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
