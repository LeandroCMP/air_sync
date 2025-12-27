import 'dart:async';

import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/application/core/session/session_service.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/services/auth/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserProfileController extends GetxController
    with LoaderMixin, MessagesMixin {
  UserProfileController({
    required AuthService authService,
    required AuthServiceApplication authServiceApplication,
    required SessionService sessionService,
  })  : _authService = authService,
        _authApp = authServiceApplication,
        _sessionService = sessionService;

  final AuthService _authService;
  final AuthServiceApplication _authApp;
  final SessionService _sessionService;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final documentController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final message = Rxn<MessageModel>();
  final isLoadingProfile = false.obs;
  final isSavingProfile = false.obs;
  final isChangingPassword = false.obs;
  final hasLoadedProfile = false.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    loaderListener(isLoadingProfile);
    messageListener(message);
    currentUser(_authApp.user.value);
    nameController.text = currentUser.value?.name ?? '';
    emailController.text = currentUser.value?.email ?? '';
    phoneController.text = currentUser.value?.phone ?? '';
    documentController.text = currentUser.value?.cpfOrCnpj ?? '';
    loadProfile();
    super.onInit();
  }

  /// GET /v1/auth/me
  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    try {
      final fresh = await _authService
          .fetchProfile()
          .timeout(const Duration(seconds: 20));
      final merged = _mergeUserData(_authApp.user.value, fresh);
      currentUser(merged);
      _authApp.user(merged);
      if (merged.name.trim().isNotEmpty) {
        nameController.text = merged.name;
      }
      if (merged.email.trim().isNotEmpty) {
        emailController.text = merged.email;
      }
      if (merged.phone.trim().isNotEmpty) {
        phoneController.text = merged.phone;
      }
      if (merged.cpfOrCnpj.trim().isNotEmpty) {
        documentController.text = merged.cpfOrCnpj;
      }
    } on TimeoutException {
      message(
        MessageModel.error(
          title: 'Tempo esgotado',
          message: 'Não conseguimos carregar seu perfil. Verifique sua conexão e tente novamente.',
        ),
      );
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Falha ao carregar perfil',
          message: _apiError(error, 'Falha ao carregar perfil.'),
        ),
      );
    } finally {
      hasLoadedProfile.value = true;
      isLoadingProfile.value = false;
    }
  }

  UserModel _mergeUserData(UserModel? previous, UserModel fresh) {
    if (previous == null) return fresh;
    String resolve(String? value, String fallback) =>
        value != null && value.trim().isNotEmpty ? value : fallback;

    final mergedPermissions =
        fresh.permissions.isNotEmpty ? fresh.permissions : previous.permissions;

    return fresh.copyWith(
      name: resolve(fresh.name, previous.name),
      email: resolve(fresh.email, previous.email),
      phone: resolve(fresh.phone, previous.phone),
      cpfOrCnpj: resolve(fresh.cpfOrCnpj, previous.cpfOrCnpj),
      role: resolve(fresh.role, previous.role),
      userLevel: fresh.userLevel != 0 ? fresh.userLevel : previous.userLevel,
      planExpiration: fresh.planExpiration ?? previous.planExpiration,
      permissions: mergedPermissions,
    );
  }

  /// PATCH /v1/auth/me
  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phoneDigits = _digitsOnly(phoneController.text);
    final documentDigits = _digitsOnly(documentController.text);
    if (name.length < 3) {
      message(
        MessageModel.error(
          title: 'Nome inválido',
          message: 'Informe um nome com pelo menos 3 caracteres.',
        ),
      );
      return;
    }
    if (!email.isEmail) {
      message(
        MessageModel.error(
          title: 'E-mail inválido',
          message: 'Informe um e-mail válido.',
        ),
      );
      return;
    }
    if (phoneDigits.isNotEmpty && phoneDigits.length < 10) {
      message(
        MessageModel.error(
          title: 'Telefone inválido',
          message: 'Informe um telefone com DDD (10 ou 11 dígitos).',
        ),
      );
      return;
    }
    if (documentDigits.isNotEmpty &&
        documentDigits.length != 11 &&
        documentDigits.length != 14) {
      message(
        MessageModel.error(
          title: 'Documento inválido',
          message: 'Informe um CPF (11 dígitos) ou CNPJ (14 dígitos).',
        ),
      );
      return;
    }
    isSavingProfile.value = true;
    try {
      final updated = await _authService.updateProfile(
        name: name,
        email: email,
        phone: phoneDigits.isEmpty ? null : phoneDigits,
        document: documentDigits.isEmpty ? null : documentDigits,
      );
      currentUser(updated);
      _authApp.user(updated);
      phoneController.text = updated.phone;
      documentController.text = updated.cpfOrCnpj;
      message(
        MessageModel.success(
          title: 'Perfil atualizado',
          message: 'Suas informações foram atualizadas.',
        ),
      );
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Falha ao salvar',
          message: _apiError(error, 'Falha ao carregar perfil.'),
        ),
      );
    } finally {
      isSavingProfile.value = false;
    }
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'\\D'), '');

  /// POST /v1/auth/change-password
  Future<void> changePassword() async {
    final current = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (current.isEmpty) {
      message(
        MessageModel.error(
          title: 'Senha atual obrigatória',
          message: 'Informe sua senha atual.',
        ),
      );
      return;
    }
    if (newPass.length < 8) {
      message(
        MessageModel.error(
          title: 'Senha fraca',
          message: 'A nova senha deve ter pelo menos 8 caracteres.',
        ),
      );
      return;
    }
    if (newPass != confirm) {
      message(
        MessageModel.error(
          title: 'Confirmação inválida',
          message: 'A confirmação precisa corresponder à nova senha.',
        ),
      );
      return;
    }

    isChangingPassword.value = true;
    try {
      await _authService.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      message(
        MessageModel.success(
          title: 'Senha alterada',
          message: 'Faça login novamente com a nova senha.',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _authService.logout();
      _sessionService.cancel();
      _authApp.user.value = null;
      Get.offAllNamed('/login');
    } catch (error) {
      message(
        MessageModel.error(
          title: 'Falha ao alterar senha',
          message: _apiError(error, 'Falha ao carregar perfil.'),
        ),
      );
    } finally {
      isChangingPassword.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    documentController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}


String _apiError(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['message'] is String && (nested['message'] as String).trim().isNotEmpty) {
        return (nested['message'] as String).trim();
      }
      if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return (data['message'] as String).trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if ((error.message ?? '').isNotEmpty) return error.message!;
  } else if (error is Exception) {
    final text = error.toString();
    if (text.trim().isNotEmpty) return text;
  }
  return fallback;
}

