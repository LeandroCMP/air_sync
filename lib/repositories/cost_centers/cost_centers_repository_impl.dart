import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/cost_center_model.dart';
import 'package:air_sync/repositories/cost_centers/cost_centers_repository.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

class CostCentersRepositoryImpl implements CostCentersRepository {
  CostCentersRepositoryImpl() : _api = Get.find<ApiClient>();

  final ApiClient _api;

  @override
  Future<List<CostCenterModel>> list({bool includeInactive = true}) async {
    try {
      final query =
          includeInactive ? {'includeInactive': true} : <String, dynamic>{};
      final res = await _api.dio
          .get('/v1/cost-centers', queryParameters: query.isEmpty ? null : query)
          .timeout(const Duration(seconds: 12));
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => CostCenterModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map>()
            .map((e) => CostCenterModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<CostCenterModel> create({
    required String name,
    String? code,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final res = await _api.dio
        .post('/v1/cost-centers', data: payload)
        .timeout(const Duration(seconds: 12));
    return CostCenterModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<CostCenterModel> update(
    String id, {
    String? name,
    String? code,
    String? description,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name.trim();
    if (code != null) payload['code'] = code.trim();
    if (description != null) payload['description'] = description.trim();
    final res = await _api.dio
        .patch('/v1/cost-centers/$id', data: payload)
        .timeout(const Duration(seconds: 12));
    return CostCenterModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<void> setActive(String id, bool active) async {
    await _api.dio
        .patch('/v1/cost-centers/$id', data: {'active': active})
        .timeout(const Duration(seconds: 10));
  }
}
