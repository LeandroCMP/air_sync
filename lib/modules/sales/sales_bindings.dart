import 'package:air_sync/modules/sales/sales_controller.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:air_sync/services/sales/sales_service.dart';
import 'package:get/get.dart';

class SalesBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocationsService>()) {
      Get.lazyPut<LocationsService>(
        () => LocationsServiceImpl(repo: Get.find()),
        fenix: true,
      );
    }
    Get.lazyPut<SalesController>(
      () => SalesController(
        service: Get.find<SalesService>(),
        costCentersService: Get.find<CostCentersService>(),
        clientService: Get.find<ClientService>(),
        inventoryService: Get.find<InventoryService>(),
        locationsService: Get.find<LocationsService>(),
      ),
    );
  }
}
