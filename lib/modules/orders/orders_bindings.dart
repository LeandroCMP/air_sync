import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/repositories/orders/orders_repository_impl.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/orders/orders_service_impl.dart';
import 'package:get/get.dart';
import './orders_controller.dart';

class OrdersBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrdersRepository>(() => OrdersRepositoryImpl());
    Get.lazyPut<OrdersService>(() => OrdersServiceImpl(repo: Get.find()));
    Get.put(OrdersController(service: Get.find()));
  }
}

