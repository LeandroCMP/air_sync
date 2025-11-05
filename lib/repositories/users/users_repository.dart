import 'package:air_sync/models/collaborator_models.dart';

abstract class UsersRepository {
  Future<List<CollaboratorModel>> list({CollaboratorRole? role});
  Future<CollaboratorModel> create(CollaboratorCreateInput input);
  Future<CollaboratorModel> update(String id, CollaboratorUpdateInput input);
  Future<void> delete(String id);
  Future<List<PermissionCatalogEntry>> permissionCatalog();
  Future<List<RolePresetModel>> rolePresets();
  Future<List<PayrollModel>> listPayroll(String userId);
  Future<PayrollModel> createPayroll(String userId, PayrollCreateInput input);
  Future<PayrollModel> updatePayroll(
    String userId,
    String payrollId,
    PayrollUpdateInput input,
  );
}
