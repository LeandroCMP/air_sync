import 'dart:ui';

import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import './login_controller.dart';

const int _signupTrialDays = 3;

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final surface = context.themeGray;
    final borderColor = context.themeLightGray.withValues(alpha: 0.5);

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
        fillColor: surface.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.themeGreen, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Obx(
            () {
              final loading = controller.isLoading.value;
              final gradientColors = loading
                  ? [const Color(0xFF0F2027), const Color(0xFF2C5364)]
                  : [const Color(0xFF0f172a), const Color(0xFF0d9488)];
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    left: loading ? -80 : -40,
                    top: loading ? 20 : 60,
                    child: _GlowCircle(
                      size: 180,
                      color: context.themeGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    right: loading ? -120 : -60,
                    bottom: 40,
                    child: _GlowCircle(
                      size: 220,
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                    ),
                  ),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxW = constraints.maxWidth.clamp(0.0, 480.0).toDouble();
                        final bottomInset = media.viewInsets.bottom;
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset > 0 ? 24 : 40),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxW),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutBack,
                                  builder: (_, value, child) => Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - value) * 18),
                                      child: child,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const FlutterLogo(size: 72),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Entre no AirSync',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: controller.emailController,
                                        builder: (_, value, __) => AnimatedOpacity(
                                          duration: const Duration(milliseconds: 250),
                                          opacity: value.text.isEmpty ? 0 : 1,
                                          child: Text(
                                            'Pronto para sincronizar, ${value.text.split('@').first}?',
                                            style: const TextStyle(color: Colors.white70),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Caso seja seu primeiro acesso, vocÃª trocarÃ¡ a senha logo apÃ³s entrar.',
                                        style: TextStyle(color: Colors.white54, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  builder: (_, value, child) => Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.98 + (value * 0.02),
                                      child: child,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(22),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 18,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                        child: Form(
                                          key: _formKey,
                                          autovalidateMode: AutovalidateMode.onUserInteraction,
                                          child: Column(
                                            children: [
                                              TextFormField(
                                                controller: controller.emailController,
                                                enabled: !loading,
                                                validator: FormValidators.validateEmail,
                                                keyboardType: TextInputType.emailAddress,
                                                textInputAction: TextInputAction.next,
                                                autofillHints: const [AutofillHints.email],
                                                style: const TextStyle(color: Colors.white),
                                                cursorColor: context.themeGreen,
                                                decoration: deco(
                                                  label: 'E-mail',
                                                  hint: 'seu@email.com',
                                                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white70),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Obx(
                                                () => TextFormField(
                                                  controller: controller.passwordController,
                                                  enabled: !loading,
                                                  validator: FormValidators.validatePassword,
                                                  textInputAction: TextInputAction.done,
                                                  autofillHints: const [AutofillHints.password],
                                                  obscureText: controller.viewPassword.value,
                                                  style: const TextStyle(color: Colors.white),
                                                  cursorColor: context.themeGreen,
                                                  decoration: deco(
                                                    label: 'Senha',
                                                    hint: '********',
                                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                                                    suffixIcon: IconButton(
                                                      onPressed: controller.viewPassword.toggle,
                                                      icon: AnimatedSwitcher(
                                                        duration: const Duration(milliseconds: 200),
                                                        child: Icon(
                                                          controller.viewPassword.value
                                                              ? Icons.visibility_off_rounded
                                                              : Icons.visibility_rounded,
                                                          key: ValueKey(controller.viewPassword.value),
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  onFieldSubmitted: (_) {
                                                    if (_formKey.currentState!.validate()) {
                                                      controller.login();
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 14),
                                              Obx(
                                                () => Row(
                                                  children: [
                                                    Switch(
                                                      value: controller.saveUserVar.value,
                                                      onChanged: loading ? null : controller.toggleRememberMe,
                                                      activeColor: context.themeGreen,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Expanded(
                                                      child: Text(
                                                        'Manter meu e-mail salvo',
                                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: loading
                                                          ? null
                                                          : () {
                                                              FocusScope.of(context).unfocus();
                                                              final email = controller.emailController.text;
                                                              controller.resetPassword(email);
                                                            },
                                                      child: const Text('Esqueci a senha'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: loading ? .6 : 1,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 250),
                                    scale: loading ? .98 : 1,
                                    child: SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: loading
                                            ? null
                                            : () {
                                                if (_formKey.currentState!.validate()) {
                                                  controller.login();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: loading
                                                  ? [
                                                      context.themeGreen.withValues(alpha: .3),
                                                      Colors.tealAccent.withValues(alpha: .3),
                                                    ]
                                                  : [context.themeGreen, Colors.tealAccent],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: loading
                                                ? const SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Text(
                                                    'Entrar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 17,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () => _showSignupSheet(context, controller),
                                    child: const Text('Criar conta como Administrador Global'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}


Future<void> _showSignupSheet(
  BuildContext context,
  LoginController controller,
) async {
  final ownerFormKey = GlobalKey<FormState>();
  final companyFormKey = GlobalKey<FormState>();
  final ownerCtrl = TextEditingController();
  final ownerEmailCtrl = TextEditingController();
  final ownerPhoneCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final documentCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  int billingDay = 5;
  int step = 0;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (innerCtx, setState) {
          const totalSteps = 2;
          final bottomPadding = MediaQuery.of(sheetCtx).viewInsets.bottom + 24;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(
                      totalSteps,
                      (index) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                          decoration: BoxDecoration(
                            color: index <= step ? context.themeGreen : Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step == 0 ? '1. Dados do responsável' : '2. Dados da empresa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step == 0
                        ? 'Informe quem será o Administrador Global.'
                        : 'Agora detalhe a empresa que utilizará o AirSync.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  if (step == 0)
                    Form(
                      key: ownerFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: ownerCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Nome completo'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Informe o nome' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: ownerEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                            validator: FormValidators.validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: ownerPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [PhoneInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Telefone'),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Informe o telefone'
                                : null,
                          ),
                        ],
                      ),
                    )
                  else
                    Form(
                      key: companyFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: companyCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Nome da empresa'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Informe o nome' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: documentCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CnpjCpfInputFormatter()],
                            decoration: const InputDecoration(labelText: 'Documento (CPF/CNPJ)'),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? 'Informe o documento'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: billingDay,
                            decoration: const InputDecoration(labelText: 'Dia da cobrança'),
                            items: List.generate(
                              28,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('Dia ${index + 1}'),
                              ),
                            ),
                            onChanged: (value) => setState(() => billingDay = value ?? 5),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: notesCtrl,
                            maxLines: 3,
                            decoration:
                                const InputDecoration(labelText: 'Observações (opcional)'),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Plano AirSync Standard - R\$ 120/m\u00EAs. Valor \u00FAnico para todos os clientes.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => step--),
                            child: const Text('Voltar'),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isSignupLoading.value
                                ? null
                                : () async {
                                    if (step == 0) {
                                      if (ownerFormKey.currentState!.validate()) {
                                        setState(() => step = 1);
                                      }
                                      return;
                                    }
                                    if (!companyFormKey.currentState!.validate()) return;
                                    final tempPassword = await controller.createTenant(
                                      companyName: companyCtrl.text.trim(),
                                      ownerName: ownerCtrl.text.trim(),
                                      ownerEmail: ownerEmailCtrl.text.trim(),
                                      ownerPhone: ownerPhoneCtrl.text.trim(),
                                      document: documentCtrl.text.trim(),
                                      billingDay: billingDay,
                                      notes: notesCtrl.text.trim().isEmpty
                                          ? null
                                          : notesCtrl.text.trim(),
                                    );
                                    if (tempPassword == null ||
                                        tempPassword.isEmpty ||
                                        !sheetCtx.mounted) {
                                      return;
                                    }
                                    final ownerEmail = ownerEmailCtrl.text.trim();
                                    await _showTempPasswordDialog(
                                      context: sheetCtx,
                                      email: ownerEmail,
                                      tempPassword: tempPassword,
                                    );
                                    if (sheetCtx.mounted) {
                                      controller.emailController.text = ownerEmail;
                                      controller.passwordController.text = tempPassword;
                                      controller.viewPassword.value = true;
                                      controller.saveUserVar.value = true;
                                      Navigator.of(sheetCtx).pop();
                                    }
                                  },
                            child: controller.isSignupLoading.value
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(step == 0 ? 'Próxima etapa' : 'Concluir cadastro'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showTempPasswordDialog({
  required BuildContext context,
  required String email,
  required String tempPassword,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      final accent = dialogCtx.themeGreen;
      final secondary = Colors.tealAccent;
      final background = dialogCtx.themeDark;
      final subtle = dialogCtx.themeTextSubtle;
      final trialEndsLabel =
          DateFormat('dd/MM').format(DateTime.now().add(const Duration(days: _signupTrialDays)));

      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 40,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.lock_open_rounded, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Senha temporária criada!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Administrador Global',
                style: TextStyle(
                  color: subtle,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senha temporária',
                      style: TextStyle(color: subtle, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      tempPassword,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use-a apenas no primeiro login. Em seguida o app solicitará a troca definitiva.',
                      style: TextStyle(color: subtle, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seu período de teste de $_signupTrialDays dias já está ativo. Você pode pagar a primeira fatura até $trialEndsLabel sem cobrança extra.',
                      style: TextStyle(color: subtle, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: tempPassword));
                        Get.snackbar(
                          'Senha copiada',
                          'Cole no campo de senha para entrar.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.black.withValues(alpha: 0.7),
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copiar senha'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.lock_clock_rounded),
                      label: const Text('Ir para login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

