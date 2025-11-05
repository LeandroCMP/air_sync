import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

import 'orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl() : _dio = Get.find<ApiClient>().dio;

  final dio.Dio _dio;

  @override
  Future<List<OrderModel>> list({
    DateTime? from,
    DateTime? to,
    String? status,
    String? technicianId,
  }) async {
    final query = <String, dynamic>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (technicianId != null && technicianId.isNotEmpty) {
      query['tech'] = technicianId;
    }

    final res = await _dio.get('/v1/orders', queryParameters: query);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromMap)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromMap)
            .toList();
      }
    }
    return [];
  }

  @override
  Future<OrderModel> getById(String id) async {
    final res = await _dio.get('/v1/orders/$id');
    return OrderModel.fromMap(_asMap(res.data));
  }

  @override
  Future<OrderModel> create({
    required String clientId,
    required String locationId,
    String? equipmentId,
    required String status,
    DateTime? scheduledAt,
    String? notes,
    List<String> technicianIds = const [],
    List<OrderChecklistInput> checklist = const [],
    List<OrderMaterialInput> materials = const [],
    List<OrderBillingItemInput> billingItems = const [],
    num billingDiscount = 0,
  }) async {
    final payload = <String, dynamic>{
      'clientId': clientId,
      'locationId': locationId,
      'status': status,
      if (equipmentId != null && equipmentId.isNotEmpty)
        'equipmentId': equipmentId,
      if (scheduledAt != null)
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (technicianIds.isNotEmpty) 'technicianIds': technicianIds,
      if (checklist.isNotEmpty) 'checklist': checklist.toJsonList(),
      if (materials.isNotEmpty) 'materials': materials.toJsonList(),
      if (billingItems.isNotEmpty) 'billingItems': billingItems.toJsonList(),
      if (billingDiscount != 0) 'billingDiscount': billingDiscount,
    };

    final res = await _dio.post('/v1/orders', data: payload);
    return OrderModel.fromMap(_asMap(res.data));
  }

  @override
  Future<OrderModel> update({
    required String orderId,
    String? status,
    DateTime? scheduledAt,
    List<String>? technicianIds,
    List<OrderChecklistInput>? checklist,
    List<OrderBillingItemInput>? billingItems,
    num? billingDiscount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) payload['status'] = status;
    if (scheduledAt != null) {
      payload['scheduledAt'] = scheduledAt.toUtc().toIso8601String();
    }
    if (technicianIds != null) payload['technicianIds'] = technicianIds;
    if (checklist != null) payload['checklist'] = checklist.toJsonList();
    if (billingItems != null) {
      payload['billingItems'] = billingItems.toJsonList();
    }
    if (billingDiscount != null) payload['billingDiscount'] = billingDiscount;
    if (notes != null) payload['notes'] = notes;

    final res = await _dio.patch('/v1/orders/$orderId', data: payload);
    return OrderModel.fromMap(_asMap(res.data));
  }

  @override
  Future<OrderModel> start(String orderId) async {
    final res = await _dio.post('/v1/orders/$orderId/start');
    return OrderModel.fromMap(_asMap(res.data));
  }

  @override
  Future<OrderModel> finish({
    required String orderId,
    required List<OrderBillingItemInput> billingItems,
    num discount = 0,
    String? signatureBase64,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'billingItems': billingItems.toJsonList(),
      'discount': discount,
    };
    if (signatureBase64 != null && signatureBase64.isNotEmpty) {
      payload['signatureBase64'] = signatureBase64;
    }
    if (notes != null && notes.isNotEmpty) payload['notes'] = notes;

    final res = await _dio.post('/v1/orders/$orderId/finish', data: payload);
    return OrderModel.fromMap(_asMap(res.data));
  }

  @override
  Future<void> reserveMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  ) async {
    if (materials.isEmpty) return;
    await _dio.post(
      '/v1/orders/$orderId/materials/reserve',
      data: {'materials': materials.toJsonList()},
    );
  }

  @override
  Future<void> deductMaterials(
    String orderId,
    List<OrderMaterialInput> materials,
  ) async {
    if (materials.isEmpty) return;
    await _dio.post(
      '/v1/orders/$orderId/materials/deduct',
      data: {'materials': materials.toJsonList()},
    );
  }

  @override
  Future<String> uploadPhoto({
    required String orderId,
    required String filename,
    required List<int> bytes,
  }) async {
    final formData = dio.FormData.fromMap({
      'file': dio.MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(
      '/v1/orders/$orderId/upload/photo',
      data: formData,
      options: dio.Options(contentType: 'multipart/form-data'),
    );
    final data = res.data;
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    if (data is Map && data['name'] != null) {
      return data['name'].toString();
    }
    return filename;
  }

  @override
  Future<String> uploadSignature({
    required String orderId,
    required String base64,
  }) async {
    final res = await _dio.post(
      '/v1/orders/$orderId/signature',
      data: {'base64': base64},
    );
    final data = res.data;
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    if (data is Map && data['signatureUrl'] != null) {
      return data['signatureUrl'].toString();
    }
    return '';
  }

  @override
  String pdfUrl(String orderId, {String type = 'report'}) {
    final base = _dio.options.baseUrl;
    return '$base/v1/orders/$orderId/pdf?type=$type';
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('Resposta inesperada do servidor.');
  }
}
