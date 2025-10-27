import 'dart:ui';
import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final media = MediaQuery.of(context);

    // Tokens visuais
    const greenA = Color(0xFF3DDC84); // verde mais frio
    const greenB = Color(0xFF2DBD6E);
    final bg = context.themeDark;
    final surface = context.themeGray;
    final borderColor = context.themeLightGray.withOpacity(0.6);

    // Helper para InputDecoration
    InputDecoration deco({
      required String label,
      String? hint,
      Widget? prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: surface.withOpacity(0.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.themeGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.clamp(0.0, 480.0) as double;
              final bottomInset = media.viewInsets.bottom;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset > 0 ? 24 : 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== Logo + Títulos (animados) =====
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0.0, ((1.0 - t) * 12.0).toDouble()),
                            child: child,
                          ),
                        ),
                        child: Column(
                          children: const [
                            FlutterLogo(size: 72),
                            SizedBox(height: 12),
                            Text(
                              'Acesse sua conta',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Entre para sincronizar dados, listas e ordens.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ===== Card translúcido com blur (animado) =====
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 480),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0.0, ((1.0 - t) * 10.0).toDouble()),
                            child: child,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.30),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Form(
                                key: formKey,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Usuário
                                    TextFormField(
                                      controller: controller.emailController,
                                      validator: FormValidators.validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                                      style: const TextStyle(color: Colors.white),
                                      cursorColor: context.themeGreen,
                                      decoration: deco(
                                        label: 'Usuário',
                                        hint: 'seu@email.com',
                                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Senha
                                    Obx(
                                      () => TextFormField(
                                        controller: controller.passwordController,
                                        validator: FormValidators.validatePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
                                        obscureText: controller.viewPassword.value,
                                        style: const TextStyle(color: Colors.white),
                                        cursorColor: context.themeGreen,
                                        decoration: deco(
                                          label: 'Senha',
                                          hint: '••••••••',
                                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                                          suffixIcon: IconButton(
                                            onPressed: controller.viewPassword.toggle,
                                            icon: Icon(
                                              controller.viewPassword.value
                                                  ? Icons.visibility_rounded
                                                  : Icons.visibility_off_rounded,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        onFieldSubmitted: (_) {
                                          if (formKey.currentState!.validate()) {
                                            controller.login();
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Lembrar + Esqueci
                                    Row(
                                      children: [
                                        SizedBox(
                                          height: 28,
                                          width: 44,
                                          child: FittedBox(
                                            fit: BoxFit.fill,
                                            child: Obx(
                                              () => Switch(
                                                value: controller.saveUserVar.value,
                                                onChanged: controller.toggleRememberMe,
                                                activeColor: context.themeGreen,
                                                inactiveThumbColor: surface,
                                                trackColor: WidgetStateProperty.all(context.themeLightGray),
                                                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Salvar usuário', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            final emailResetCtrl = TextEditingController(
                                              text: controller.emailController.text,
                                            );
                                            Get.bottomSheet(
                                              _ResetSheet(
                                                emailController: emailResetCtrl,
                                                onSubmit: () {
                                                  final email = emailResetCtrl.text.trim();
                                                  if (email.isEmail) {
                                                    Get.back();
                                                    controller.resetPassword(email);
                                                  } else {
                                                    Get.snackbar(
                                                      'Erro',
                                                      'Digite um e-mail válido.',
                                                      snackPosition: SnackPosition.BOTTOM,
                                                      backgroundColor: Colors.red.withOpacity(0.85),
                                                      colorText: Colors.white,
                                                    );
                                                  }
                                                },
                                              ),
                                              isScrollControlled: true,
                                            );
                                          },
                                          child: const Text('Esqueceu a senha?'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ===== Botão Entrar (gradiente coerente + texto branco) =====
                      Obx(
                        () => GestureDetector(
                          onTap: controller.isLoading.value
                              ? null
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    controller.login();
                                  }
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: controller.isLoading.value
                                    ? [greenA.withOpacity(0.35), greenB.withOpacity(0.35)]
                                    : const [greenA, greenB],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: controller.isLoading.value
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: greenB.withOpacity(0.32),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        color: Colors.white, // contraste melhor
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===== Sheet de reset de senha com estilo do app =====
class _ResetSheet extends StatelessWidget {
  final TextEditingController emailController;
  final VoidCallback onSubmit;
  const _ResetSheet({required this.emailController, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 16,
        right: 16,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1214),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Recuperar senha',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'E-mail',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1B1B1D),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Colors.tealAccent, width: 1.5),
              ),
              labelStyle: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D672),
                    foregroundColor: const Color(0xFF0C0C0E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Colors.transparent),
                  ),
                  onPressed: onSubmit,
                  child: const Text('Resetar senha', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
