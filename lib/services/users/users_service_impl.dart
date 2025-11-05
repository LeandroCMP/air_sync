import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/repositories/users/users_repository.dart';

import 'users_service.dart';

class UsersServiceImpl implements UsersService {
  UsersServiceImpl({required UsersRepository repository})
    : _repository = repository;

  final UsersRepository _repository;

  @override
  Future<List<CollaboratorModel>> list({CollaboratorRole? role}) =>
      _repository.list(role: role);

  @override
  Future<CollaboratorModel> create(CollaboratorCreateInput input) =>
      _repository.create(input);

  @override
  Future<CollaboratorModel> update(String id, CollaboratorUpdateInput input) =>
      _repository.update(id, input);

  @override
  Future<void> delete(String id) => _repository.delete(id);

  @override
  Future<List<PermissionCatalogEntry>> permissionCatalog() =>
      _repository.permissionCatalog();

  @override
  Future<List<RolePresetModel>> rolePresets() => _repository.rolePresets();

  @override
  Future<List<PayrollModel>> listPayroll(String userId) =>
      _repository.listPayroll(userId);

  @override
  Future<PayrollModel> createPayroll(String userId, PayrollCreateInput input) =>
      _repository.createPayroll(userId, input);

  @override
  Future<PayrollModel> updatePayroll(
    String userId,
    String payrollId,
    PayrollUpdateInput input,
  ) => _repository.updatePayroll(userId, payrollId, input);
}
