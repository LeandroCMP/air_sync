import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/repositories/inventory/inventory_repository_impl.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/inventory/inventory_service_impl.dart';
import 'package:get/get.dart';
import './inventory_controller.dart';

class InventoryBindings implements Bindings {
    @override
    void dependencies() {
        Get.lazyPut<InventoryRepository>(
          () => InventoryRepositoryImpl());
        Get.lazyPut<InventoryService>(
          () => InventoryServiceImpl(inventoryRepository: Get.find()));
        Get.put(InventoryController(
          inventoryService: Get.find()),
        );
    }
}
