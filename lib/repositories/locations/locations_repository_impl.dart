import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'locations_repository.dart';

class LocationsRepositoryImpl implements LocationsRepository {
  final ApiClient _api = Get.find<ApiClient>();
  @override
  Future<LocationModel> create({required String clientId, required String label, Map<String, String?> address = const {}, String? notes}) async {
    final payload = {
      'clientId': clientId,
      'label': label,
      'address': address,
      if (notes != null) 'notes': notes,
    };
    final res = await _api.dio.post('/v1/locations', data: payload);
    return LocationModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<List<LocationModel>> listByClient(String clientId) async {
    try {
      final res = await _api.dio.get('/v1/locations', queryParameters: {'clientId': clientId});
      final data = res.data;
      if (data is List) {
        return data.map((e) => LocationModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }
}

