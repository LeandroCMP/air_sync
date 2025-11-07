import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/repositories/inventory/inventory_repository_impl.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/inventory/inventory_service_impl.dart';
import 'package:get/get.dart';
import './inventory_item_history_controller.dart';

class InventoryItemHistoryBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InventoryRepository>()) {
      Get.lazyPut<InventoryRepository>(
        InventoryRepositoryImpl.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<InventoryService>()) {
      Get.lazyPut<InventoryService>(
        () => InventoryServiceImpl(inventoryRepository: Get.find()),
        fenix: true,
      );
    }
    Get.put(InventoryItemHistoryController(inventoryService: Get.find()));
  }
}
