import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/repositories/orders/orders_repository_impl.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/orders/orders_service_impl.dart';
import 'package:get/get.dart';

import 'order_detail_controller.dart';

class OrderDetailBindings implements Bindings {
  OrderDetailBindings({required this.orderId});

  final String orderId;

  @override
  void dependencies() {
    if (!Get.isRegistered<OrdersRepository>()) {
      Get.lazyPut<OrdersRepository>(() => OrdersRepositoryImpl());
    }
    if (!Get.isRegistered<OrdersService>()) {
      Get.lazyPut<OrdersService>(() => OrdersServiceImpl(repo: Get.find()));
    }
    Get.put(OrderDetailController(orderId: orderId, service: Get.find()));
  }
}
