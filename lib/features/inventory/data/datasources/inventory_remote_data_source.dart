import 'package:dio/dio.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchItems({String? text}) async {
    final response = await _dio.get<List<dynamic>>('/v1/inventory/items', queryParameters: text != null ? {'text': text} : null);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchItem(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/inventory/items/$id');
    return response.data ?? <String, dynamic>{};
  }

  Future<void> move(Map<String, dynamic> payload) async {
    await _dio.post('/v1/inventory/movements', data: payload);
  }

  Future<List<Map<String, dynamic>>> lowStock() async {
    final response = await _dio.get<List<dynamic>>('/v1/inventory/low-stock');
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }
}
