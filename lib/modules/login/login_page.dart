import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Hero(tag: 'logo', child: const FlutterLogo(size: 120)),
                  const SizedBox(height: 100),
                  TextFormField(
                    controller: controller.emailController,
                    validator: FormValidators.validateEmail,
                    style: TextStyle(color: Colors.white),
                    cursorColor: context.themeGreen,
                    decoration: InputDecoration(
                      labelText: 'Usuário',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: context.themeGray,
                          width: 2,
                        ),
                      ),
                      suffixIcon: Icon(Icons.email),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: context.themeGreen,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    return TextFormField(
                      controller: controller.passwordController,
                      validator: FormValidators.validatePassword,
                      style: TextStyle(color: Colors.white),
                      cursorColor: context.themeGreen,
                      obscureText: controller.viewPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        labelStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.themeGray,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.themeGreen,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.viewPassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => controller.viewPassword.toggle(),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        "Salvar Usuário",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        height: 30,
                        width: 45,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Obx(() {
                            return Switch(
                              value: controller.saveUserVar.value,
                              trackColor: WidgetStateProperty.all(
                                context.themeLightGray,
                              ),
                              trackOutlineColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              inactiveThumbColor: context.themeGray,
                              activeColor: context.themeGreen,
                              onChanged: controller.toggleRememberMe,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: SizedBox(
                      width: double.maxFinite,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.themeGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            controller.login();
                          }
                        },
                        child: Text(
                          "Entrar",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.themeGray,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: () {
                      final emailResetCtrl = TextEditingController(
                        text: controller.emailController.text,
                      );
                      Get.bottomSheet(
                        Container(
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 50,
                            left: 16,
                            right: 16,
                            top: 50,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recuperar senha',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.themeGreen,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailResetCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'E-mail',
                                  labelStyle: TextStyle(color: Colors.white),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: context.themeGray,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: Icon(Icons.email),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: context.themeGreen,
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: context.themeGreen,
                                        side: BorderSide(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                      onPressed: () {
                                        final email =
                                            emailResetCtrl.text.trim();
                                        if (email.isEmail) {
                                          Get.back();
                                          controller.resetPassword(email);
                                        } else {
                                          Get.snackbar(
                                            'Erro',
                                            'Digite um e-mail válido.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.red
                                                .withOpacity(0.8),
                                            colorText: Colors.white,
                                          );
                                        }
                                      },
                                      child: Text(
                                        'Resetar senha',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: context.themeGray,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: context.themeGray,
                                        ),
                                      ),
                                      onPressed: () => Get.back(),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        isScrollControlled: true,
                      );
                    },
                    child: const Text(
                      "Esqueceu a senha?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
