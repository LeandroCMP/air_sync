import 'package:air_sync/modules/sales/sales_controller.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:air_sync/services/sales/sales_service.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:air_sync/services/users/users_service_impl.dart';
import 'package:air_sync/repositories/users/users_repository.dart';
import 'package:air_sync/repositories/users/users_repository_impl.dart';
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
    if (!Get.isRegistered<UsersRepository>()) {
      Get.lazyPut<UsersRepository>(() => UsersRepositoryImpl(), fenix: true);
    }
    if (!Get.isRegistered<UsersService>()) {
      Get.lazyPut<UsersService>(
        () => UsersServiceImpl(repository: Get.find()),
        fenix: true,
      );
    }
    Get.lazyPut<SalesController>(
      () => SalesController(
        service: Get.find<SalesService>(),
        clientService: Get.find<ClientService>(),
        inventoryService: Get.find<InventoryService>(),
        locationsService: Get.find<LocationsService>(),
        usersService: Get.find<UsersService>(),
      ),
    );
  }
}
