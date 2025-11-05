import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl() : _dio = Get.find<ApiClient>().dio;

  final Dio _dio;
  static const _basePath = '/v1/users';

  @override
  Future<List<CollaboratorModel>> list({CollaboratorRole? role}) async {
    final query = <String, dynamic>{};
    if (role != null) query['role'] = role.name;
    final res = await _dio.get(
      _basePath,
      queryParameters: query.isEmpty ? null : query,
    );
    final data = res.data;
    Iterable<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map && data['items'] is List) {
      rawList = data['items'] as List;
    } else {
      rawList = const [];
    }
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(CollaboratorModel.fromMap)
        .toList();
  }

  @override
  Future<CollaboratorModel> create(CollaboratorCreateInput input) async {
    final res = await _dio.post(_basePath, data: input.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CollaboratorModel.fromMap(data);
    }
    if (data is Map) {
      return CollaboratorModel.fromMap(Map<String, dynamic>.from(data));
    }
    throw StateError('Resposta inesperada ao criar colaborador');
  }

  @override
  Future<CollaboratorModel> update(
    String id,
    CollaboratorUpdateInput input,
  ) async {
    final res = await _dio.patch('$_basePath/$id', data: input.toJson());
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CollaboratorModel.fromMap(data);
    }
    if (data is Map) {
      return CollaboratorModel.fromMap(Map<String, dynamic>.from(data));
    }
    throw StateError('Resposta inesperada ao atualizar colaborador');
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete('$_basePath/$id');
  }

  @override
  Future<List<PermissionCatalogEntry>> permissionCatalog() async {
    final res = await _dio.get('$_basePath/permission-catalog');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(PermissionCatalogEntry.fromMap)
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(PermissionCatalogEntry.fromMap)
          .toList();
    }
    return const [];
  }

  @override
  Future<List<RolePresetModel>> rolePresets() async {
    final res = await _dio.get('$_basePath/role-presets');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(RolePresetModel.fromMap)
          .toList();
    }
    return const [];
  }

  @override
  Future<List<PayrollModel>> listPayroll(String userId) async {
    final res = await _dio.get('$_basePath/$userId/payroll');
    final data = res.data;
    Iterable<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map && data['items'] is List) {
      rawList = data['items'] as List;
    } else {
      rawList = const [];
    }
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(PayrollModel.fromMap)
        .toList();
  }

  @override
  Future<PayrollModel> createPayroll(
    String userId,
    PayrollCreateInput input,
  ) async {
    final res = await _dio.post(
      '$_basePath/$userId/payroll',
      data: input.toJson(),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return PayrollModel.fromMap(data);
    }
    if (data is Map) {
      return PayrollModel.fromMap(Map<String, dynamic>.from(data));
    }
    throw StateError('Resposta inesperada ao criar holerite');
  }

  @override
  Future<PayrollModel> updatePayroll(
    String userId,
    String payrollId,
    PayrollUpdateInput input,
  ) async {
    final res = await _dio.patch(
      '$_basePath/$userId/payroll/$payrollId',
      data: input.toJson(),
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return PayrollModel.fromMap(data);
    }
    if (data is Map) {
      return PayrollModel.fromMap(Map<String, dynamic>.from(data));
    }
    throw StateError('Resposta inesperada ao atualizar holerite');
  }
}
