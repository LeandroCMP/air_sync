import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/finance_transaction.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<FinanceTransactionModel>> list({required String type, String? status, DateTime? from, DateTime? to}) async {
    try {
      final params = <String, dynamic>{'type': type};
      if (status != null) params['status'] = status;
      if (from != null) params['from'] = from.toUtc().toIso8601String();
      if (to != null) params['to'] = to.toUtc().toIso8601String();
      final res = await _api.dio.get('/v1/finance/transactions', queryParameters: params);
      final data = res.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>().map(FinanceTransactionModel.fromMap).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> pay({required String id, required String method, required double amount}) async {
    await _api.dio.patch('/v1/finance/transactions/$id/pay', data: {'method': method, 'amount': amount});
  }
}

