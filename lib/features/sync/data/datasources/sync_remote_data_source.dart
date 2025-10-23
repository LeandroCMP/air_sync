import 'package:dio/dio.dart';

class SyncRemoteDataSource {
  SyncRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchChanges(DateTime? since, String scope) async {
    final query = {
      'includeDeleted': true,
      'scope': scope,
      if (since != null) 'since': since.toIso8601String(),
    };
    final response = await _dio.get<List<dynamic>>('/v1/sync/changes', queryParameters: query);
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> replay(String endpoint, String method, Map<String, dynamic>? body, Map<String, dynamic>? headers) async {
    final options = Options(method: method, headers: headers);
    await _dio.fetch(RequestOptions(path: endpoint, data: body, method: method, headers: headers));
  }
}
