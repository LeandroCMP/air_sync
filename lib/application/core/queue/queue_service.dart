import 'dart:convert';

import 'package:air_sync/application/core/connectivity/connectivity_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueueAction {
  final String type; // 'order.finish' | ...
  final Map<String, dynamic> data;
  QueueAction({required this.type, required this.data});

  Map<String, dynamic> toMap() => {'type': type, 'data': data};
  factory QueueAction.fromMap(Map<String, dynamic> map) =>
      QueueAction(type: (map['type'] ?? '').toString(), data: Map<String, dynamic>.from(map['data'] ?? {}));
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

  Future<void> enqueueFinishOrder({required String orderId, required Map<String, dynamic> payload}) async {
    pending.add(QueueAction(type: 'order.finish', data: {'orderId': orderId, 'payload': payload}));
    await _save();
  }

  Future<void> processPending() async {
    if (pending.isEmpty) return;
    final orders = Get.isRegistered<OrdersService>() ? Get.find<OrdersService>() : null;
    if (orders == null) return;
    final toRemove = <QueueAction>[];
    for (final action in pending) {
      try {
        if (action.type == 'order.finish') {
          final id = action.data['orderId'] as String;
          final payload = Map<String, dynamic>.from(action.data['payload'] as Map);
          await orders.finish(orderId: id, payload: payload);
          toRemove.add(action);
        }
      } catch (_) {
        // mantém na fila se falhou
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
      // ignore formato inválido
    }
  }
}

