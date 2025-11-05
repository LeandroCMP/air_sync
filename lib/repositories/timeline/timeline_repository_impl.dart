import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/timeline_entry_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'timeline_repository.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<TimelineEntryModel>> listByClient(String clientId) async {
    try {
      final res = await _api.dio.get('/v1/timeline', queryParameters: {'clientId': clientId});
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => TimelineEntryModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<TimelineEntryModel> create({
    required String clientId,
    required String type,
    required String text,
    DateTime? at,
    String? by,
  }) async {
    final payload = {
      'clientId': clientId,
      'type': type,
      'text': text,
      if (at != null) 'at': at.toUtc().toIso8601String(),
      if (by != null) 'by': by,
    };
    final res = await _api.dio.post('/v1/timeline', data: payload);
    return TimelineEntryModel.fromMap(Map<String, dynamic>.from(res.data));
  }
}


