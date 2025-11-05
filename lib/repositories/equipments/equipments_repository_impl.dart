import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'equipments_repository.dart';

class EquipmentsRepositoryImpl implements EquipmentsRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<EquipmentModel> create({
    required String clientId,
    required String locationId,
    required String room,
    String? brand,
    String? model,
    String? type,
    int? btus,
    DateTime? installDate,
    String? serial,
    String? notes,
  }) async {
    final payload = {
      'clientId': clientId,
      'locationId': locationId,
      'room': room,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (type != null) 'type': type,
      if (btus != null) 'btus': btus,
      if (installDate != null)
        'installDate': installDate.toUtc().toIso8601String(),
      if (serial != null) 'serial': serial,
      if (notes != null) 'notes': notes,
    };
    final res = await _api.dio.post('/v1/equipment', data: payload);
    return EquipmentModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<List<EquipmentModel>> listByClient(String clientId) async {
    try {
      final res = await _api.dio.get(
        '/v1/equipment',
        queryParameters: {'clientId': clientId},
      );
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => EquipmentModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<List<EquipmentModel>> listBy(
    String clientId, {
    String? locationId,
  }) async {
    try {
      final query = <String, dynamic>{'clientId': clientId};
      if (locationId != null && locationId.isNotEmpty) {
        query['locationId'] = locationId;
      }
      final res = await _api.dio.get('/v1/equipment', queryParameters: query);
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => EquipmentModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<EquipmentModel> update({
    required String id,
    String? locationId,
    String? brand,
    String? model,
    String? type,
    int? btus,
    String? room,
    DateTime? installDate,
    String? serial,
    String? notes,
    bool includeNotes = false,
  }) async {
    final payload = <String, dynamic>{};
    if (locationId != null) payload['locationId'] = locationId;
    if (brand != null) payload['brand'] = brand;
    if (model != null) payload['model'] = model;
    if (type != null) payload['type'] = type;
    if (btus != null) payload['btus'] = btus;
    if (room != null) payload['room'] = room;
    if (installDate != null) {
      payload['installDate'] = installDate.toUtc().toIso8601String();
    }
    if (serial != null) payload['serial'] = serial;
    if (includeNotes) {
      payload['notes'] = notes;
    }
    final res = await _api.dio.patch('/v1/equipment/$id', data: payload);
    return EquipmentModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<void> delete(String id) async {
    await _api.dio.delete('/v1/equipment/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> listHistory(String equipmentId) async {
    try {
      final res = await _api.dio.get('/v1/equipment/$equipmentId/history');
      final data = res.data;
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> move(
    String id, {
    required String toLocationId,
    required String toRoom,
    String? toClientId,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'toLocationId': toLocationId,
      'toRoom': toRoom,
      if (toClientId != null && toClientId.isNotEmpty) 'toClientId': toClientId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    await _api.dio.post('/v1/equipment/$id/move', data: payload);
  }

  @override
  Future<void> replace(
    String id, {
    required Map<String, dynamic> newEquipment,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'newEquipment': newEquipment,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    await _api.dio.post('/v1/equipment/$id/replace', data: payload);
  }

  @override
  String reportUrl(String id, {String? newOwner}) {
    final base = _api.dio.options.baseUrl;
    final owner =
        (newOwner == null || newOwner.isEmpty)
            ? ''
            : '?newOwner=${Uri.encodeComponent(newOwner)}';
    return '$base/v1/equipment/$id/report$owner';
  }
}
