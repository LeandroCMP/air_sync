import 'dart:convert';

import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueueAction {
  final String type; // 'order.finish' | ...
  final Map<String, dynamic> data;
  QueueAction({required this.type, required this.data});

  Map<String, dynamic> toMap() => {'type': type, 'data': data};
  factory QueueAction.fromMap(Map<String, dynamic> map) => QueueAction(
    type: (map['type'] ?? '').toString(),
    data: Map<String, dynamic>.from(map['data'] ?? {}),
  );
}

class QueueService extends GetxService {
  static const _storageKey = 'offline_queue_v1';
  final RxList<QueueAction> pending = <QueueAction>[].obs;

  Future<QueueService> init() async {
    await _load();
    // tenta processar quando reconectar
    Get.find<ConnectivityService>().isOnline.listen((online) {
      if (online) {
        processPending();
      }
    });
    return this;
  }

  Future<void> enqueueFinishOrder({
    required String orderId,
    List<OrderMaterialInput> materials = const [],
    required List<OrderBillingItemInput> billingItems,
    num discount = 0,
    String? signatureBase64,
    String? notes,
    List<OrderPaymentInput> payments = const [],
  }) async {
    pending.add(
      QueueAction(
        type: 'order.finish',
        data: {
          'orderId': orderId,
          if (materials.isNotEmpty)
            'materials': materials.toJsonList(includeMetadata: true),
          'billingItems': billingItems.toJsonList(),
          'discount': discount,
          if (signatureBase64 != null && signatureBase64.isNotEmpty)
            'signatureBase64': signatureBase64,
          if (notes != null) 'notes': notes,
          if (payments.isNotEmpty) 'payments': payments.toJsonList(),
        },
      ),
    );
    await _save();
  }

  Future<void> processPending() async {
    if (pending.isEmpty) return;
    final orders =
        Get.isRegistered<OrdersService>() ? Get.find<OrdersService>() : null;
    if (orders == null) return;
    final toRemove = <QueueAction>[];
    for (final action in pending) {
      try {
        if (action.type == 'order.finish') {
          final id = action.data['orderId'] as String;
          final materialsRaw = (action.data['materials'] as List?) ?? [];
          final materials =
              materialsRaw.whereType<Map>().map((e) {
                String? normalize(dynamic value) {
                  if (value == null) return null;
                  final text = value is String ? value : value.toString();
                  final trimmed = text.trim();
                  return trimmed.isEmpty ? null : trimmed;
                }

                final normalizedName = normalize(e['itemName'] ?? e['name']);
                final normalizedDescription =
                    normalize(e['description']) ?? normalizedName;
                final rawPrice = e['unitPrice'];
                final parsedPrice =
                    rawPrice is num
                        ? rawPrice.toDouble()
                        : double.tryParse('$rawPrice');
                final rawCost = e['unitCost'];
                final parsedCost =
                    rawCost is num
                        ? rawCost.toDouble()
                        : double.tryParse('$rawCost');
                return OrderMaterialInput(
                  itemId: (e['itemId'] ?? '').toString(),
                  qty: (e['qty'] ?? 0) as num,
                  itemName: normalizedName,
                  description: normalizedDescription,
                  unitPrice: parsedPrice,
                  unitCost: parsedCost,
                );
              }).toList();
          final billingRaw = (action.data['billingItems'] as List?) ?? [];
          final billingItems =
              billingRaw
                  .whereType<Map>()
                  .map(
                    (e) => OrderBillingItemInput(
                      type: (e['type'] ?? 'service').toString(),
                      name: (e['name'] ?? '').toString(),
                      qty: (e['qty'] ?? 0) as num,
                      unitPrice: (e['unitPrice'] ?? 0) as num,
                    ),
                  )
                  .toList();
          final discount = (action.data['discount'] ?? 0) as num;
          final signatureValue = action.data['signatureBase64'] as String?;
          final notes = action.data['notes'] as String?;
          final paymentsRaw = (action.data['payments'] as List?) ?? [];
          var payments =
              paymentsRaw
                  .whereType<Map>()
                  .map(
                    (e) => OrderPaymentInput(
                      method: (e['method'] ?? 'PIX').toString(),
                      amount: ((e['amount'] ?? 0) as num).toDouble(),
                      installments:
                          e['installments'] is num
                              ? (e['installments'] as num).toInt()
                              : null,
                    ),
                  )
                  .toList();
          final billingTotal =
              billingItems.fold<double>(
                0,
                (sum, item) =>
                    sum + (item.qty.toDouble() * item.unitPrice.toDouble()),
              ) -
              discount.toDouble();
          final double totalDue = billingTotal < 0 ? 0.0 : billingTotal;
          if (payments.isEmpty) {
            payments = [OrderPaymentInput(method: 'PIX', amount: totalDue)];
          }
          await orders.finish(
            orderId: id,
            billingItems: billingItems,
            discount: discount,
            signatureBase64:
                (signatureValue == null || signatureValue.isEmpty)
                    ? null
                    : signatureValue,
            notes: notes,
            payments: payments,
          );
          if (materials.isNotEmpty) {
            await orders.deductMaterials(id, materials);
          }
          toRemove.add(action);
        }
      } catch (_) {
        // mant??m na fila se falhou
      }
    }
    if (toRemove.isNotEmpty) {
      pending.removeWhere((a) => toRemove.contains(a));
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = pending.map((e) => e.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      pending.assignAll(list.map(QueueAction.fromMap));
    } catch (_) {
      // ignore formato inv??lido
    }
  }
}
