import 'package:dio/dio.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchOrders({Map<String, dynamic>? filters}) async {
    final response = await _dio.get<List<dynamic>>('/v1/orders', queryParameters: filters);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchOrder(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/orders/$id');
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/orders', data: data);
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateOrder(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/orders/$id', data: data);
    return response.data ?? <String, dynamic>{};
  }

  Future<void> startOrder(String id) async {
    await _dio.post('/v1/orders/$id/start');
  }

  Future<Map<String, dynamic>> finishOrder(String id, Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/orders/$id/finish', data: data);
    return response.data ?? <String, dynamic>{};
  }

  Future<void> reserveMaterials(String id, List<Map<String, dynamic>> items) async {
    await _dio.post('/v1/orders/$id/materials/reserve', data: items);
  }

  Future<void> deductMaterials(String id, List<Map<String, dynamic>> items) async {
    await _dio.post('/v1/orders/$id/materials/deduct', data: items);
  }
}
