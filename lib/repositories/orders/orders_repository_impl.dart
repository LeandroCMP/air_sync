import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<OrderModel>> list({DateTime? from, DateTime? to, String? status}) async {
    try {
      final params = <String, dynamic>{};
      if (from != null) params['from'] = from.toUtc().toIso8601String();
      if (to != null) params['to'] = to.toUtc().toIso8601String();
      if (status != null && status.isNotEmpty) params['status'] = status;

      final res = await _api.dio.get('/v1/orders', queryParameters: params);
      final data = res.data;
      if (data is List) {
        return data
            .cast<Map<String, dynamic>>()
            .map((e) => OrderModel.fromMap(e))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> finish({required String orderId, required Map<String, dynamic> payload}) async {
    await _api.dio.post('/v1/orders/$orderId/finish', data: payload);
  }

  @override
  Future<void> start(String orderId) async {
    await _api.dio.post('/v1/orders/$orderId/start');
  }

  @override
  Future<void> reserveMaterials(String orderId, List<Map<String, dynamic>> items) async {
    await _api.dio.post('/v1/orders/$orderId/materials/reserve', data: items);
  }

  @override
  String pdfUrl(String orderId, {String type = 'report'}) {
    final base = _api.dio.options.baseUrl;
    return '$base/v1/orders/$orderId/pdf?type=$type';
  }
}
