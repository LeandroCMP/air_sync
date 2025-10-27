import 'dart:convert';
import 'package:air_sync/repositories/finance/finance_repository.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService extends GetxService {
  final RxBool isSyncing = false.obs;
  final Rx<DateTime?> lastSync = Rx<DateTime?>(null);

  Future<void> syncInitial() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await Get.find<OrdersService>().list(
        from: DateTime.now(),
        to: DateTime.now().add(const Duration(days: 1)),
      );
      final ar = await Get.find<FinanceRepository>().list(
        type: 'receivable',
        status: 'pending',
        from: DateTime(DateTime.now().year, DateTime.now().month, 1),
        to: DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
      );
      await prefs.setString('cache_orders', jsonEncode(orders.map((e) => {
            'id': e.id,
            'status': e.status,
            'scheduledAt': e.scheduledAt?.toIso8601String(),
            'clientName': e.clientName,
            'location': e.location,
            'equipment': e.equipment,
          }).toList()));
      await prefs.setString('cache_ar', jsonEncode(ar.map((e) => {
            'id': e.id,
            'type': e.type,
            'status': e.status,
            'amount': e.amount,
            'paidAmount': e.paidAmount,
            'dueDate': e.dueDate?.toIso8601String(),
            'description': e.description,
            'orderId': e.originOrderId,
          }).toList()));
      lastSync.value = DateTime.now();
    } finally {
      isSyncing.value = false;
    }
  }
}
