import 'package:dio/dio.dart';

class FinanceRemoteDataSource {
  FinanceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchTransactions({String? type}) async {
    final response = await _dio.get<List<dynamic>>('/v1/finance/transactions', queryParameters: type != null ? {'type': type} : null);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchTransaction(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/finance/transactions/$id');
    return response.data ?? <String, dynamic>{};
  }

  Future<void> pay(String id, Map<String, dynamic> payload) async {
    await _dio.patch('/v1/finance/transactions/$id/pay', data: payload);
  }

  Future<Map<String, dynamic>> fetchDre() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/reports/dre');
    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchKpis() async {
    final response = await _dio.get<List<dynamic>>('/v1/reports/kpis');
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }
}
