import 'dart:async';

import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/core/errors/auth_failure.dart';
import 'package:air_sync/application/core/services/local_storage_service.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:air_sync/services/signups/signups_service.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginController extends GetxController with MessagesMixin, LoaderMixin {
  final AuthServiceApplication _authServiceApplication;
  final AuthService _authService;
  final SignupsService _signupsService;
  static const int _trialGraceDays = 3;
  static const bool _trialGraceTestMode = bool.fromEnvironment('TRIAL_GRACE_TEST', defaultValue: true);
  static const _secureEmailKey = 'biometric_email';
  static const _securePasswordKey = 'biometric_password';
  static const _secureEnabledKey = 'biometric_enabled';
  static const _secureNamespace = 'login_biometric';

  LoginController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
    required SignupsService signupsService,
  })  : _authService = authService,
        _authServiceApplication = authServiceApplication,
        _signupsService = signupsService;

  final _storage = LocalStorageService();
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  // UI states
  final viewPassword = true.obs;
  final saveUserVar = true.obs;
  final isLoading = false.obs;
  final isSignupLoading = false.obs;
  final canUseBiometrics = false.obs;
  final biometricEnabled = false.obs;
  final hasBiometricCredentials = false.obs;

  // Form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final message = Rxn<MessageModel>();

  @override
  void onInit() {
    _loadRememberMe();
    _initBiometrics();
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  Future<void> _loadRememberMe() async {
    saveUserVar.value = true;
    await _storage.setRememberMe(true);
    emailController.text = await _storage.getEmail();
  }

  void toggleRememberMe(bool? value) {
    // Alterna o switch; persiste "lembrar" e o e-mail apenas se valido.
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
          title: 'E-mail invalido',
          message: 'Informe um e-mail valido.',
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

      await _storage.setRememberMe(true);
      await _storage.setEmail(email);

      _authServiceApplication.user(user);
      Get.find<SessionService>().onLogin(user);
      await _maybeSaveBiometricCredentials(email, password);

      if (user.mustChangePassword) {
        message(
          MessageModel.info(
            title: 'Senha temporária detectada',
            message: 'Defina uma nova senha para liberar o acesso.',
          ),
        );
        Get.offAllNamed(
          '/change-temp-password',
          arguments: {'tempPassword': password},
        );
        return;
      } else {

        message(
          MessageModel.success(
            title: 'Tudo certo',
            message: 'Sessão iniciada com sucesso.',
          ),
        );

        await _maybeShowTrialGrace(user);

        final activationOk = await _requireActivationCode(user);
        if (!activationOk) {
          isLoading.value = false;
          return;
        }

        Get.offAllNamed('/home');

      }
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
          message: 'Informe um e-mail valido para redefinir a senha.',
        ),
      );
      return;
    }

    try {
      await _authService.requestPasswordReset(target);
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'E-mail de redefinicao de senha enviado.',
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

  Future<bool> createTenant({
    required String companyName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String document,
    required String password,
    int? billingDay,
    String? notes,
  }) async {
    if (isSignupLoading.value) return false;
    isSignupLoading.value = true;
    try {
      final ok = await _signupsService.registerTenant(
        companyName: companyName,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerPhone: ownerPhone,
        document: document,
        password: password,
        billingDay: billingDay,
        notes: notes,
      );
      if (ok) {
        unawaited(_storage.setActivationPending(ownerEmail, true));
      }
      return ok;
    } on Exception catch (e) {
      final failure = AuthFailure.fromException(e);
      message(
        MessageModel.error(
          title: 'Não foi possível concluir o cadastro',
          message: failure.message,
        ),
      );
      return false;
    } finally {
      isSignupLoading.value = false;
    }
  }

  Future<void> _initBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      canUseBiometrics.value = canCheck && supported;
      final enabled =
          await _secureStorage.read(key: '$_secureNamespace|$_secureEnabledKey') == 'true';
      biometricEnabled.value = enabled;
      if (enabled) {
        hasBiometricCredentials.value = await _hasStoredCredentials();
      }
    } catch (_) {
      canUseBiometrics.value = false;
      biometricEnabled.value = false;
      hasBiometricCredentials.value = false;
    }
  }

  Future<void> enableBiometric(bool value) async {
    biometricEnabled.value = value;
    if (!value) {
      hasBiometricCredentials.value = false;
      await _secureStorage.delete(key: '$_secureNamespace|$_secureEmailKey');
      await _secureStorage.delete(key: '$_secureNamespace|$_securePasswordKey');
      await _secureStorage.write(key: '$_secureNamespace|$_secureEnabledKey', value: 'false');
      return;
    }
    await _secureStorage.write(key: '$_secureNamespace|$_secureEnabledKey', value: 'true');
    await _maybeSaveBiometricCredentials(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
  }

  Future<void> biometricLogin() async {
    if (!biometricEnabled.value || !canUseBiometrics.value) {
      message(
        MessageModel.error(
          title: 'Biometria',
          message: 'Ative a biometria após um login bem-sucedido.',
        ),
      );
      return;
    }
    final creds = await _readStoredCredentials();
    if (creds == null) {
      message(
        MessageModel.error(
          title: 'Biometria',
          message: 'Não encontramos credenciais salvas. Faça login e ative novamente.',
        ),
      );
      biometricEnabled.value = false;
      return;
    }
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para entrar',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!didAuth) return;
      emailController.text = creds.$1;
      passwordController.text = creds.$2;
      saveUserVar.value = true;
      await login();
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Biometria',
          message: 'Não foi possível autenticar via biometria.',
        ),
      );
    }
  }

  Future<void> _maybeSaveBiometricCredentials(String email, String password) async {
    if (!biometricEnabled.value || email.isEmpty || password.isEmpty) return;
    await _secureStorage.write(
      key: '$_secureNamespace|$_secureEmailKey',
      value: email,
    );
    await _secureStorage.write(
      key: '$_secureNamespace|$_securePasswordKey',
      value: password,
    );
    hasBiometricCredentials.value = true;
  }

  Future<bool> _hasStoredCredentials() async {
    final email = await _secureStorage.read(key: '$_secureNamespace|$_secureEmailKey');
    final password = await _secureStorage.read(key: '$_secureNamespace|$_securePasswordKey');
    return (email?.isNotEmpty ?? false) && (password?.isNotEmpty ?? false);
  }

  Future<(String, String)?> _readStoredCredentials() async {
    final email = await _secureStorage.read(key: '$_secureNamespace|$_secureEmailKey');
    final password = await _secureStorage.read(key: '$_secureNamespace|$_securePasswordKey');
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }
    return (email, password);
  }

  Future<void> ensureActivationPendingFlag(String email) async {
    if (email.isEmpty) return;
    await _storage.setActivationPending(email, true);
  }

  Future<void> _maybeShowTrialGrace(UserModel user) async {
    if (!user.isOwner || !_trialGraceTestMode) return;
    final alreadyShown = await _storage.isGraceNoticeShown(user.id);
    if (alreadyShown) return;

    final graceLimit = DateTime.now().add(const Duration(days: _trialGraceDays));
    final formatted = DateFormat('dd/MM').format(graceLimit);

    message(
      MessageModel.info(
        title: 'Carência inicial (teste)',
        message:
            'Aviso: sua fatura inicial tem $_trialGraceDays dias de carência. Você pode pagar agora ou até $formatted sem cobrança extra.',
      ),
    );
    await _storage.setGraceNoticeShown(user.id, true);
  }

  Future<bool> _requireActivationCode(UserModel user) async {
    final userKey = user.id.isNotEmpty ? user.id : user.email;
    if (userKey.isEmpty) return true;

    final alreadyVerified = await _storage.isActivationVerified(userKey);
    if (alreadyVerified) return true;

    final pendingEmail = user.email.trim();
    final pending =
        pendingEmail.isNotEmpty ? await _storage.isActivationPending(pendingEmail) : false;
    if (!pending) {
      // Se não marcamos como pendente (ex: conta antiga), não exigimos.
      return true;
    }

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return true;

    final codeCtrl = TextEditingController();

    Future<void> tryAutofillFromClipboard() async {
      final data = await Clipboard.getData('text/plain');
      final txt = data?.text ?? '';
      final match = RegExp(r'\\b(\\d{4,6})\\b').firstMatch(txt);
      if (match != null && codeCtrl.text.isEmpty) {
        codeCtrl.text = match.group(1)!;
        codeCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: codeCtrl.text.length),
        );
      }
    }

    await tryAutofillFromClipboard();
    if (!ctx.mounted) return false;

    final accepted = await showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ative sua conta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enviamos um SMS com seu código de ativação. Digite abaixo para liberar o primeiro acesso.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(Icons.sms_rounded, color: Colors.white70),
                  hintText: '000000',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                ),
                onTap: tryAutofillFromClipboard,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: tryAutofillFromClipboard,
                icon: const Icon(Icons.paste_rounded, color: Colors.white70),
                label: const Text(
                  'Puxar código do SMS automaticamente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final code = codeCtrl.text.replaceAll(RegExp('[^0-9]'), '');
                  if (code.length < 4 || code.length > 6) {
                    Get.snackbar(
                      'Código inválido',
                      'Informe o código de 4 a 6 dígitos enviado por SMS.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black.withValues(alpha: 0.8),
                      colorText: Colors.white,
                    );
                    return;
                  }
                  Navigator.of(sheetCtx).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Ativar e continuar'),
              ),
            ],
          ),
        );
      },
    );

    if (accepted == true) {
      await _storage.setActivationVerified(userKey, true);
      if (pendingEmail.isNotEmpty) {
        await _storage.setActivationPending(pendingEmail, false);
      }
      return true;
    }
    return false;
  }
}
