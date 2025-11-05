import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/fleet_vehicle_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'fleet_repository.dart';

class FleetRepositoryImpl implements FleetRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<FleetVehicleModel>> list({String? text, String? sort, String? order}) async {
    try {
      final qp = <String, dynamic>{
        if (text != null && text.isNotEmpty) 'text': text,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        if (order != null && order.isNotEmpty) 'order': order,
      };
      final res = await _api.dio
          .get('/v1/fleet/vehicles', queryParameters: qp.isEmpty ? null : qp)
          .timeout(const Duration(seconds: 12));
      final data = res.data;

      List<dynamic>? _extractList(dynamic d) {
        if (d is List) return d;
        if (d is Map) {
          dynamic inner = d['data'] ?? d['items'] ?? d['results'] ?? d['vehicles'] ?? d['rows'] ?? d['content'];
          if (inner is List) return inner;
          if (inner is Map) {
            final nested = inner['items'] ?? inner['data'] ?? inner['docs'];
            if (nested is List) return nested;
          }
          for (final entry in d.values) {
            if (entry is List && entry.isNotEmpty && entry.first is Map) {
              return entry as List;
            }
            if (entry is Map) {
              for (final v in entry.values) {
                if (v is List && v.isNotEmpty && v.first is Map) return v as List;
              }
            }
          }
        }
        return null;
      }

      final list = _extractList(data) ?? [];
      return list
          .whereType<Map>()
          .map((e) => FleetVehicleModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException {
      return [];
    }
  }

  @override
  Future<void> check({required String id, int? odometer, int? fuelLevel, String? notes}) async {
    final payload = <String, dynamic>{
      'at': DateTime.now().toUtc().toIso8601String(),
      if (odometer != null) 'km': odometer,
      if (fuelLevel != null) 'fuelLevel': fuelLevel,
      if (notes != null) 'notes': notes,
    };
    await _api.dio.post('/v1/fleet/vehicles/$id/check', data: payload);
  }

  @override
  Future<void> fuel({required String id, required double liters, required double price, required String fuelType, int? odometer}) async {
    final ft = fuelType.trim().toLowerCase();
    const allowed = {'gasoline', 'ethanol', 'diesel', 'gnv', 'electric'};
    final normalized = allowed.contains(ft) ? ft : 'gasoline';
    final payload = <String, dynamic>{
      'at': DateTime.now().toUtc().toIso8601String(),
      'liters': liters,
      'cost': price,
      'fuelType': normalized,
      if (odometer != null) 'km': odometer,
    };
    await _api.dio.post('/v1/fleet/vehicles/$id/fuel', data: payload);
  }

  @override
  Future<void> maintenance({required String id, required String description, double? cost, int? odometer}) async {
    final payload = <String, dynamic>{
      'type': 'general',
      'at': DateTime.now().toUtc().toIso8601String(),
      if (description.isNotEmpty) 'notes': description,
    };
    if (cost != null) payload['cost'] = cost;
    if (odometer != null) payload['atKm'] = odometer;
    await _api.dio.post('/v1/fleet/vehicles/$id/maintenance', data: payload);
  }

  @override
  Future<FleetVehicleModel> create({required String plate, String? model, int? year, required int odometer}) async {
    final payload = <String, dynamic>{
      'plate': plate,
      'odometer': odometer,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
    };
    final res = await _api.dio.post('/v1/fleet/vehicles', data: payload);
    return FleetVehicleModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<FleetVehicleModel> update(String id, {String? plate, String? model, int? year, int? odometer}) async {
    final payload = <String, dynamic>{};
    if (plate != null) payload['plate'] = plate;
    if (model != null) payload['model'] = model;
    if (year != null) payload['year'] = year;
    if (odometer != null) payload['odometer'] = odometer;
    final res = await _api.dio.patch('/v1/fleet/vehicles/$id', data: payload);
    try {
      return FleetVehicleModel.fromMap(Map<String, dynamic>.from(res.data));
    } catch (_) {
      final all = await list();
      return all.firstWhere(
        (e) => e.id == id,
        orElse: () => FleetVehicleModel(id: id, plate: plate ?? '', model: model, year: year, odometer: odometer ?? 0),
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    await _api.dio.delete('/v1/fleet/vehicles/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> listEvents(
    String id, {
    int page = 1,
    int limit = 50,
    List<String>? types,
    DateTime? from,
    DateTime? to,
    String? sort,
    String? order,
  }) async {
    try {
      final qp = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (types != null && types.isNotEmpty) 'types': types.join(','),
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (sort != null) 'sort': sort,
        if (order != null) 'order': order,
      };
      final res = await _api.dio.get('/v1/fleet/vehicles/$id/events', queryParameters: qp);
      final data = res.data;

      List<dynamic>? _extractList(dynamic d) {
        if (d is List) return d;
        if (d is Map) {
          dynamic inner = d['events'] ?? d['items'] ?? d['data'] ?? d['results'] ?? d['rows'] ?? d['content'];
          if (inner is List) return inner;
          if (inner is Map) {
            final nested = inner['items'] ?? inner['data'] ?? inner['events'] ?? inner['docs'];
            if (nested is List) return nested;
          }
          for (final entry in d.values) {
            if (entry is List && entry.isNotEmpty && entry.first is Map) return entry as List;
            if (entry is Map) {
              for (final v in entry.values) {
                if (v is List && v.isNotEmpty && v.first is Map) return v as List;
              }
            }
          }
        }
        return null;
      }

      final list = _extractList(data) ?? const [];
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }
}


