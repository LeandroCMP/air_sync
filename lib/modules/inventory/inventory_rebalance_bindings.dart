import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/repositories/inventory/inventory_repository_impl.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/inventory/inventory_service_impl.dart';
import 'package:get/get.dart';

import 'inventory_rebalance_controller.dart';

class InventoryRebalanceBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InventoryRepository>()) {
      Get.lazyPut<InventoryRepository>(() => InventoryRepositoryImpl());
    }
    if (!Get.isRegistered<InventoryService>()) {
      Get.lazyPut<InventoryService>(
        () => InventoryServiceImpl(inventoryRepository: Get.find()),
      );
    }
    Get.put(
      InventoryRebalanceController(service: Get.find()),
    );
  }
}

