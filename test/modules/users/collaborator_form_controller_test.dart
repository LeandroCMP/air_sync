import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/user_model.dart';
import 'package:air_sync/modules/users/users_controller.dart';
import 'package:air_sync/modules/users/widgets/collaborator_form.dart';
import 'package:air_sync/services/users/users_service.dart';

class _FakeUsersService implements UsersService {
  _FakeUsersService({
    required this.permissionCatalogEntries,
    required this.rolePresetsEntries,
  });

  final List<PermissionCatalogEntry> permissionCatalogEntries;
  final List<RolePresetModel> rolePresetsEntries;
  final List<CollaboratorModel> collaborators = [];
  int _sequence = 0;

  List<String> _presetFor(CollaboratorRole role) {
    return rolePresetsEntries
        .firstWhere(
          (preset) => preset.role == role,
          orElse: () => RolePresetModel(role: role, permissions: const []),
        )
        .permissions;
  }

  @override
  Future<List<CollaboratorModel>> list({CollaboratorRole? role}) async {
    if (role == null) {
      return List.unmodifiable(collaborators);
    }
    return collaborators.where((c) => c.role == role).toList();
  }

  @override
  Future<CollaboratorModel> create(CollaboratorCreateInput input) async {
    final permissions = input.permissions ?? _presetFor(input.role);
    final model = CollaboratorModel(
      id: (++_sequence).toString(),
      name: input.name,
      email: input.email,
      role: input.role,
      permissions: permissions,
      active: input.active ?? true,
      hourlyCost: input.hourlyCost,
      compensation: CollaboratorCompensation(
        salary: input.salary,
        paymentDay: input.paymentDay,
        paymentFrequency: input.paymentFrequency,
        paymentMethod: input.paymentMethod,
        notes: input.compensationNotes,
      ),
    );
    collaborators.add(model);
    return model;
  }

  @override
  Future<CollaboratorModel> update(
    String id,
    CollaboratorUpdateInput input,
  ) async {
    final index = collaborators.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('Collaborator not found');
    }
    final current = collaborators[index];
    final updated = CollaboratorModel(
      id: current.id,
      name: input.name ?? current.name,
      email: current.email,
      role: input.role ?? current.role,
      permissions: input.permissions ?? current.permissions,
      active: input.active ?? current.active,
      hourlyCost: input.hourlyCost ?? current.hourlyCost,
      compensation: CollaboratorCompensation(
        salary: input.salary ?? current.compensation?.salary,
        paymentDay: input.paymentDay ?? current.compensation?.paymentDay,
        paymentFrequency:
            input.paymentFrequency ?? current.compensation?.paymentFrequency,
        paymentMethod:
            input.paymentMethod ?? current.compensation?.paymentMethod,
        notes: input.compensationNotes ?? current.compensation?.notes,
      ),
    );
    collaborators[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    collaborators.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<PermissionCatalogEntry>> permissionCatalog() async {
    return permissionCatalogEntries;
  }

  @override
  Future<List<RolePresetModel>> rolePresets() async {
    return rolePresetsEntries;
  }

  // Unused endpoints for these tests
  @override
  Future<PayrollModel> createPayroll(String userId, PayrollCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<PayrollModel> updatePayroll(
    String userId,
    String payrollId,
    PayrollUpdateInput input,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PayrollModel>> listPayroll(String userId) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUsersService service;
  late UsersController usersController;

  setUp(() async {
    Get.testMode = true;
    Get.reset();

    final auth = AuthServiceApplication(user: Rxn<UserModel>());
    auth.user.value = UserModel(
      id: 'user-1',
      name: 'Tester',
      email: 'tester@example.com',
      phone: '',
      dateBorn: null,
      userLevel: 0,
      planExpiration: null,
      cpfOrCnpj: '',
      permissions: const ['users.write'],
    );
    Get.put<AuthServiceApplication>(auth);

    service = _FakeUsersService(
      permissionCatalogEntries: [
        PermissionCatalogEntry(
          code: 'fleet.read',
          label: 'Ver frota',
          module: 'fleet',
        ),
        PermissionCatalogEntry(
          code: 'users.write',
          label: 'Gerenciar colaboradores',
          module: 'users',
        ),
        PermissionCatalogEntry(
          code: 'inventory.read',
          label: 'Ver estoque',
          module: 'inventory',
        ),
      ],
      rolePresetsEntries: [
        RolePresetModel(
          role: CollaboratorRole.tech,
          permissions: const ['fleet.read'],
        ),
        RolePresetModel(
          role: CollaboratorRole.manager,
          permissions: const ['users.write', 'inventory.read'],
        ),
        RolePresetModel(
          role: CollaboratorRole.admin,
          permissions: const ['users.write'],
        ),
      ],
    );

    usersController = UsersController(service: service);
    await usersController.loadPermissionCatalog();
    await usersController.loadRolePresets();
  });

  tearDown(() {
    Get.reset();
  });

  test('mantÃ©m presets quando alterna papel sem permissÃµes customizadas', () {
    final formController = CollaboratorFormController(
      usersController: usersController,
    );
    formController.onInit();

    expect(
      formController.selectedPermissions,
      equals(
        service.rolePresetsEntries
            .firstWhere((preset) => preset.role == CollaboratorRole.tech)
            .permissions,
      ),
    );

    formController.updateRole(CollaboratorRole.manager);

    expect(
      formController.selectedPermissions,
      equals(
        service.rolePresetsEntries
            .firstWhere((preset) => preset.role == CollaboratorRole.manager)
            .permissions,
      ),
    );
    expect(formController.useCustomPermissions.value, isFalse);
  });

  test('nÃ£o permite desativar administradores e exibe mensagem de erro', () {
    final formController = CollaboratorFormController(
      usersController: usersController,
    );
    formController.onInit();
    formController.updateRole(CollaboratorRole.admin);

    usersController.message.value = null;
    formController.toggleActive(false);

    expect(formController.active.value, isTrue);
    final message = usersController.message.value;
    expect(message, isNotNull);
    expect(message!.type, MessageType.error);
  });
}
