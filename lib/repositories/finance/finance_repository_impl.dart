import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/finance_anomaly_model.dart';
import 'package:air_sync/models/finance_audit_model.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/models/finance_forecast_model.dart';
import 'package:air_sync/models/finance_transaction.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<FinanceTransactionModel>> list({
    required String type,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'type': type,
        'page': page,
        'limit': limit,
      };
      if (status != null) params['status'] = status;
      if (from != null) params['from'] = from.toUtc().toIso8601String();
      if (to != null) params['to'] = to.toUtc().toIso8601String();
      final res = await _api.dio.get(
        '/v1/finance/transactions',
        queryParameters: params,
      );
      final data = res.data;
      if (data is List) {
        return data
            .cast<Map<String, dynamic>>()
            .map(FinanceTransactionModel.fromMap)
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> pay({
    required String id,
    required String method,
    double? amount,
    String? idempotencyKey,
  }) async {
    final payload = <String, dynamic>{
      'method': method,
      if (amount != null) 'amount': amount,
      if ((idempotencyKey ?? '').isNotEmpty) 'idempotencyKey': idempotencyKey,
    };
    await _api.dio.patch(
      '/v1/finance/transactions/$id/pay',
      data: payload,
    );
  }

  @override
  Future<FinanceDashboardModel> dashboard({
    String? month,
  }) async {
    final params = <String, dynamic>{};
    if (month != null && month.isNotEmpty) {
      params['month'] = month;
    }
    final res = await _api.dio
        .get(
          '/v1/finance/dashboard',
          queryParameters: params.isEmpty ? null : params,
        )
        .timeout(const Duration(seconds: 12));
    final data = res.data;
    if (data is Map) {
      return FinanceDashboardModel.fromMap(Map<String, dynamic>.from(data));
    }
    return FinanceDashboardModel.fromMap({});
  }

  @override
  Future<FinanceAuditModel> audit() async {
    final res = await _api.dio
        .get('/v1/finance/audit')
        .timeout(const Duration(seconds: 12));
    final data = res.data;
    if (data is Map) {
      return FinanceAuditModel.fromMap(Map<String, dynamic>.from(data));
    }
    return const FinanceAuditModel(orders: [], purchases: []);
  }

  @override
  Future<FinanceForecastModel> forecast({
    int days = 30,
  }) async {
    final params = <String, dynamic>{'days': days};
    final res = await _api.dio
        .get('/v1/finance/forecast', queryParameters: params)
        .timeout(const Duration(seconds: 12));
    final data = res.data;
    if (data is Map) {
      return FinanceForecastModel.fromMap(Map<String, dynamic>.from(data));
    }
    return const FinanceForecastModel(days: 0, timeline: []);
  }

  @override
  Future<void> allocateIndirectCosts({
    required DateTime from,
    required DateTime to,
    List<String> categories = const [],
  }) async {
    final payload = <String, dynamic>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    };
    if (categories.isNotEmpty) payload['categories'] = categories;
    await _api.dio
        .post('/v1/finance/allocations/indirect', data: payload)
        .timeout(const Duration(seconds: 12));
  }

  @override
  @override
  Future<FinanceAnomalyReport> anomalies({
    required String month,
  }) async {
    final params = <String, dynamic>{'month': month};
    final res = await _api.dio
        .post(
          '/v1/finance/insights/anomalies',
          queryParameters: params,
        )
        .timeout(const Duration(seconds: 20));
    return FinanceAnomalyReport.fromResponse(res.data);
  }
}
