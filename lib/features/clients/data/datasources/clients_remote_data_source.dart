import 'package:dio/dio.dart';

class ClientsRemoteDataSource {
  ClientsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchClients({String? text}) async {
    final response = await _dio.get<List<dynamic>>('/v1/clients', queryParameters: text != null ? {'text': text} : null);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchClient(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/clients/$id');
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/clients', data: data);
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateClient(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/clients/$id', data: data);
    return response.data ?? <String, dynamic>{};
  }

  Future<void> deleteClient(String id) async {
    await _dio.delete('/v1/clients/$id');
  }
}
