import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'change_temp_password_controller.dart';

class ChangeTempPasswordPage extends GetView<ChangeTempPasswordController> {
  const ChangeTempPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Definir nova senha'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(
        () => Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Por segurança, defina uma nova senha antes de continuar.',
                  style: TextStyle(color: context.themeTextSubtle),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.hideNewPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Nova senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.hideNewPassword.value
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: controller.hideNewPassword.toggle,
                      ),
                    ),
                    validator: (value) =>
                        value != null && value.length >= 6 ? null : 'Mínimo 6 caracteres',
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.hideConfirmPassword.value,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nova senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.hideConfirmPassword.value
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: controller.hideConfirmPassword.toggle,
                      ),
                    ),
                    validator: (value) =>
                        value == controller.newPasswordController.text
                            ? null
                            : 'As senhas precisam ser iguais',
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            controller.submit();
                          }
                        },
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar nova senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
