import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/contract_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'contracts_repository.dart';

class ContractsRepositoryImpl implements ContractsRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<ContractModel>> list() async {
    try {
      final res = await _api.dio.get('/v1/contracts');
      final data = res.data;
      List list = const [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        final inner = data['items'] ?? data['data'] ?? data['contracts'] ?? data['results'] ?? data['rows'] ?? data['content'];
        if (inner is List) list = inner;
      }
      return list
          .whereType<Map>()
          .map((e) => ContractModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<ContractModel> create({
    required String clientId,
    required String planName,
    required int intervalMonths,
    required int slaHours,
    required double priceMonthly,
    required List<String> equipmentIds,
    String? notes,
  }) async {
    final payload = {
      'clientId': clientId,
      'plan': {
        'name': planName,
        'intervalMonths': intervalMonths,
        'slaHours': slaHours,
      },
      'priceMonthly': priceMonthly,
      'equipmentIds': equipmentIds,
      if (notes != null) 'notes': notes,
    };
    final res = await _api.dio.post('/v1/contracts', data: payload);
    return ContractModel.fromMap(Map<String, dynamic>.from(res.data));
  }
}

