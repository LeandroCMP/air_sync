import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'purchases_repository.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  final ApiClient _api = Get.find<ApiClient>();

  @override
  Future<List<PurchaseModel>> list() async {
    try {
      final res = await _api.dio
          .get('/v1/purchases')
          .timeout(const Duration(seconds: 12));
      final data = res.data;

      List<dynamic>? extractList(dynamic d) {
        if (d is List) return d;
        if (d is Map) {
          dynamic inner =
              d['data'] ??
              d['items'] ??
              d['results'] ??
              d['purchases'] ??
              d['rows'] ??
              d['content'];
          if (inner is List) return inner;
          if (inner is Map) {
            final nested = inner['items'] ?? inner['data'] ?? inner['docs'];
            if (nested is List) return nested;
          }
          // Fallback: find first list-of-maps that looks like purchases
          for (final entry in d.values) {
            if (entry is List && entry.isNotEmpty && entry.first is Map) {
              return entry;
            }
            if (entry is Map) {
              final innerVals = entry.values;
              for (final v in innerVals) {
                if (v is List && v.isNotEmpty && v.first is Map) {
                  return v;
                }
              }
            }
          }
        }
        return null;
      }

      // If a single object is returned, try to parse as one purchase
      if (data is Map &&
          (data['items'] is List ||
              data['supplierId'] != null ||
              data['_id'] != null ||
              data['id'] != null)) {
        try {
          return [PurchaseModel.fromMap(Map<String, dynamic>.from(data))];
        } catch (_) {}
      }

      final list = extractList(data) ?? [];
      final parsed = <PurchaseModel>[];
      for (final e in list) {
        try {
          if (e is Map) {
            parsed.add(PurchaseModel.fromMap(Map<String, dynamic>.from(e)));
          }
        } catch (_) {
          // skip invalid element
        }
      }
      return parsed;
    } on DioException {
      return [];
    }
  }

  @override
  Future<PurchaseModel> create({
    required String supplierId,
    required List<PurchaseItemModel> items,
    String status = 'ordered',
    double? freight,
    String? notes,
    DateTime? paymentDueDate,
  }) async {
    final payload = {
      'supplierId': supplierId,
      'status': status,
      'items': items.map((it) {
        final map = <String, dynamic>{
          'itemId': it.itemId,
          'qty': it.qty,
          'unitCost': it.unitCost,
        };
        if ((it.description ?? '').trim().isNotEmpty) {
          map['description'] = it.description!.trim();
        }
        if ((it.orderId ?? '').trim().isNotEmpty) {
          map['orderId'] = it.orderId!.trim();
        }
        if ((it.costCenterId ?? '').trim().isNotEmpty) {
          map['costCenterId'] = it.costCenterId!.trim();
        }
        return map;
      }).toList(),
      if (freight != null) 'freight': freight,
      if (notes != null) 'notes': notes,
      if (paymentDueDate != null)
        'paymentDueDate': paymentDueDate.toUtc().toIso8601String(),
    };
    final res = await _api.dio
        .post('/v1/purchases', data: payload)
        .timeout(const Duration(seconds: 15));
    return PurchaseModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<void> receive({required String id, DateTime? receivedAt}) async {
    final payload = <String, dynamic>{};
    if (receivedAt != null) {
      payload['receivedAt'] = receivedAt.toUtc().toIso8601String();
    }
    await _api.dio
        .patch('/v1/purchases/$id/receive', data: payload)
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<PurchaseModel> update({
    required String id,
    String? supplierId,
    List<PurchaseItemModel>? items,
    String? status,
    double? freight,
    String? notes,
    DateTime? paymentDueDate,
  }) async {
    final payload = <String, dynamic>{};
    if (supplierId != null) payload['supplierId'] = supplierId;
    if (status != null) payload['status'] = status;
    if (freight != null) payload['freight'] = freight;
    if (notes != null) payload['notes'] = notes;
    if (paymentDueDate != null) {
      payload['paymentDueDate'] = paymentDueDate.toUtc().toIso8601String();
    }
    if (items != null) {
      payload['items'] = items.map((it) {
        final map = <String, dynamic>{
          'itemId': it.itemId,
          'qty': it.qty,
          'unitCost': it.unitCost,
        };
        if ((it.description ?? '').trim().isNotEmpty) {
          map['description'] = it.description!.trim();
        }
        if ((it.orderId ?? '').trim().isNotEmpty) {
          map['orderId'] = it.orderId!.trim();
        }
        if ((it.costCenterId ?? '').trim().isNotEmpty) {
          map['costCenterId'] = it.costCenterId!.trim();
        }
        return map;
      }).toList();
    }
    final res = await _api.dio
        .patch('/v1/purchases/$id', data: payload)
        .timeout(const Duration(seconds: 15));
    return PurchaseModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<PurchaseModel> cancel({required String id, String? reason}) async {
    final payload = <String, dynamic>{};
    if (reason != null && reason.trim().isNotEmpty) {
      payload['reason'] = reason.trim();
    }
    final res = await _api.dio
        .patch('/v1/purchases/$id/cancel', data: payload)
        .timeout(const Duration(seconds: 15));
    return PurchaseModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<PurchaseModel> submit(String id, {String? notes}) =>
      _patchFlowAction(
        id: id,
        action: 'submit',
        payload:
            (notes != null && notes.trim().isNotEmpty)
                ? {'notes': notes.trim()}
                : null,
      );

  @override
  Future<PurchaseModel> approve(String id, {String? notes}) =>
      _patchFlowAction(
        id: id,
        action: 'approve',
        payload:
            (notes != null && notes.trim().isNotEmpty)
                ? {'notes': notes.trim()}
                : null,
      );

  @override
  Future<PurchaseModel> markAsOrdered(String id, {String? externalId}) =>
      _patchFlowAction(
        id: id,
        action: 'order',
        payload:
            (externalId != null && externalId.trim().isNotEmpty)
                ? {'orderCode': externalId.trim()}
                : null,
      );

  Future<PurchaseModel> _patchFlowAction({
    required String id,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    final data = (payload == null || payload.isEmpty) ? null : payload;
    final res = await _api.dio
        .patch('/v1/purchases/$id/$action', data: data)
        .timeout(const Duration(seconds: 12));
    return PurchaseModel.fromMap(Map<String, dynamic>.from(res.data));
  }
}
