import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UsersController extends GetxController with LoaderMixin, MessagesMixin {
  UsersController({required UsersService service}) : _service = service;

  final UsersService _service;
  final AuthServiceApplication _authApp = Get.find<AuthServiceApplication>();

  UserModel? get _currentUser => _authApp.user.value;
  bool get canManageCollaborators =>
      _currentUser?.hasPermission('users.write') ?? false;
  bool get canViewPayroll =>
      _currentUser?.hasAnyPermission(['finance.read', 'finance.write']) ??
      false;
  bool get canManagePayroll =>
      _currentUser?.hasPermission('finance.write') ?? false;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final collaborators = <CollaboratorModel>[].obs;
  final filterRole = Rxn<CollaboratorRole>();
  final deletingIds = <String>{}.obs;

  final permissions = <PermissionCatalogEntry>[].obs;
  final presets = <RolePresetModel>[].obs;
  final isLoadingPermissions = false.obs;

  final payrollByUser = <String, List<PayrollModel>>{}.obs;
  final payrollLoading = <String>{}.obs;

  final searchCtrl = TextEditingController();

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    if (!canManageCollaborators) {
      message(
        MessageModel.error(
          title: 'Acesso negado',
          message:
              'Seu usuário não possui permissão para gerenciar colaboradores.',
        ),
      );
      Future.microtask(() => Get.back());
      super.onInit();
      return;
    }
    await Future.wait([
      loadCollaborators(),
      loadPermissionCatalog(),
      loadRolePresets(),
    ]);
    super.onInit();
  }

  Future<void> loadCollaborators() async {
    isLoading(true);
    try {
      final list = await _service.list(role: filterRole.value);
      collaborators.assignAll(list);
    } catch (error) {
      _emitError('Falha ao carregar colaboradores', error);
    } finally {
      isLoading(false);
    }
  }

  Future<void> applyRoleFilter(CollaboratorRole? role) async {
    filterRole.value = role;
    await loadCollaborators();
  }

  Future<void> loadPermissionCatalog() async {
    if (permissions.isNotEmpty) return;
    isLoadingPermissions(true);
    try {
      final list = await _service.permissionCatalog();
      permissions.assignAll(list);
    } catch (error) {
      _emitError('Falha ao carregar permissões', error);
    } finally {
      isLoadingPermissions(false);
    }
  }

  Future<void> loadRolePresets() async {
    if (presets.isNotEmpty) return;
    try {
      final list = await _service.rolePresets();
      presets.assignAll(list);
    } catch (error) {
      _emitError('Falha ao carregar presets de papel', error);
    }
  }

  List<String> defaultPermissionsForRole(CollaboratorRole role) {
    for (final preset in presets) {
      if (preset.role == role) {
        return preset.permissions;
      }
    }
    return const [];
  }

  bool _isProtectedRole(CollaboratorRole? role) =>
      role == CollaboratorRole.admin || role == CollaboratorRole.owner;

  Future<bool> createCollaborator(CollaboratorCreateInput input) async {
    if (!canManageCollaborators) {
      message(
        MessageModel.error(
          title: 'Acesso negado',
          message: 'Sem permissão para criar colaboradores.',
        ),
      );
      return false;
    }
    if (_isProtectedRole(input.role) && input.active == false) {
      message(
        MessageModel.error(
          title: 'Operação inválida',
          message: 'Administradores não podem ser inativados.',
        ),
      );
      return false;
    }
    isLoading(true);
    try {
      final created = await _service.create(input);
      collaborators.insert(0, created);
      message(
        MessageModel.success(
          title: 'Colaborador criado',
          message: '${created.name} foi adicionado.',
        ),
      );
      return true;
    } catch (error) {
      _emitError('Falha ao criar colaborador', error);
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateCollaborator(
    String id,
    CollaboratorUpdateInput input,
  ) async {
    if (!canManageCollaborators) {
      message(
        MessageModel.error(
          title: 'Acesso negado',
          message: 'Sem permissão para atualizar colaboradores.',
        ),
      );
      return false;
    }
    CollaboratorRole? newRole;
    final targetIndex = collaborators.indexWhere((element) => element.id == id);
    final existing = targetIndex == -1 ? null : collaborators[targetIndex];
    if (input.role != null) {
      newRole = input.role;
    } else if (existing != null) {
      newRole = existing.role;
    }
    if ((_isProtectedRole(existing?.role) || _isProtectedRole(newRole)) &&
        input.active == false) {
      message(
        MessageModel.error(
          title: 'Operação inválida',
          message: 'Administradores não podem ser inativados.',
        ),
      );
      return false;
    }
    isLoading(true);
    try {
      final updated = await _service.update(id, input);
      final index = collaborators.indexWhere((element) => element.id == id);
      if (index != -1) {
        collaborators[index] = updated;
      }
      message(
        MessageModel.success(
          title: 'Colaborador atualizado',
          message: '${updated.name} foi atualizado.',
        ),
      );
      return true;
    } catch (error) {
      _emitError('Falha ao atualizar colaborador', error);
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCollaborator(String id) async {
    if (!canManageCollaborators) {
      message(
        MessageModel.error(
          title: 'Acesso negado',
          message: 'Sem permissão para excluir colaboradores.',
        ),
      );
      return;
    }
    if (deletingIds.contains(id)) return;
    deletingIds.add(id);
    deletingIds.refresh();
    try {
      await _service.delete(id);
      collaborators.removeWhere((element) => element.id == id);
      message(
        MessageModel.success(
          title: 'Colaborador removido',
          message: 'O colaborador foi excluído com sucesso.',
        ),
      );
    } catch (error) {
      _emitError('Falha ao excluir colaborador', error);
    } finally {
      deletingIds.remove(id);
      deletingIds.refresh();
    }
  }

  Future<void> loadPayroll(String userId) async {
    if (!canViewPayroll) {
      message(
        MessageModel.info(
          title: 'Permissão necessária',
          message: 'Sem permissão para visualizar holerites.',
        ),
      );
      return;
    }
    if (payrollLoading.contains(userId)) return;
    payrollLoading.add(userId);
    payrollLoading.refresh();
    try {
      final list = await _service.listPayroll(userId);
      payrollByUser[userId] = list;
      payrollByUser.refresh();
    } catch (error) {
      _emitError('Falha ao carregar holerites', error);
    } finally {
      payrollLoading.remove(userId);
      payrollLoading.refresh();
    }
  }

  Future<bool> createPayroll(String userId, PayrollCreateInput input) async {
    if (!canManagePayroll) {
      message(
        MessageModel.error(
          title: 'Acesso negado',
          message: 'Sem permissão para registrar holerites.',
        ),
      );
      return false;
    }
    payrollLoading.add(userId);
    payrollLoading.refresh();
    try {
      final payroll = await _service.createPayroll(userId, input);
      final list = payrollByUser[userId] ?? <PayrollModel>[];
      payrollByUser[userId] = [payroll, ...list];
      payrollByUser.refresh();
      message(
        MessageModel.success(
          title: 'Holerite criado',
          message: 'Holerite ${payroll.reference} registrado.',
        ),
      );
      return true;
    } catch (error) {
      _emitError('Falha ao criar holerite', error);
      return false;
    } finally {
      payrollLoading.remove(userId);
      payrollLoading.refresh();
    }
  }

  Future<bool> updatePayroll(
    String userId,
    String payrollId,
    PayrollUpdateInput input,
  ) async {
    if (!canManagePayroll) {
      message(
        MessageModel.error(
          title: 'Acesso negado',
          message: 'Sem permissão para atualizar holerites.',
        ),
      );
      return false;
    }
    payrollLoading.add(userId);
    payrollLoading.refresh();
    try {
      final payroll = await _service.updatePayroll(userId, payrollId, input);
      final list = payrollByUser[userId] ?? <PayrollModel>[];
      final index = list.indexWhere((element) => element.id == payrollId);
      if (index != -1) {
        list[index] = payroll;
        payrollByUser[userId] = List<PayrollModel>.from(list);
        payrollByUser.refresh();
      }
      message(
        MessageModel.success(
          title: 'Holerite atualizado',
          message: 'Registro ${payroll.reference} atualizado.',
        ),
      );
      return true;
    } catch (error) {
      _emitError('Falha ao atualizar holerite', error);
      return false;
    } finally {
      payrollLoading.remove(userId);
      payrollLoading.refresh();
    }
  }

  void _emitError(String title, Object error) {
    final detail = _apiError(error, 'Ocorreu um erro inesperado.');
    message(MessageModel.error(title: title, message: detail));
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


  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
