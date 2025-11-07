import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/repositories/orders/orders_repository_impl.dart';
import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/repositories/client/client_repository_impl.dart';
import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/client/client_service_impl.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/equipments/equipments_service_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/repositories/inventory/inventory_repository_impl.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/inventory/inventory_service_impl.dart';
import 'package:air_sync/services/orders/order_label_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/orders/orders_service_impl.dart';
import 'package:air_sync/repositories/users/users_repository.dart';
import 'package:air_sync/repositories/users/users_repository_impl.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:air_sync/services/users/users_service_impl.dart';
import 'package:air_sync/modules/orders/orders_controller.dart';
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
    if (!Get.isRegistered<ClientRepository>()) {
      Get.lazyPut<ClientRepository>(ClientRepositoryImpl.new, fenix: true);
    }
    if (!Get.isRegistered<ClientService>()) {
      Get.lazyPut<ClientService>(
        () => ClientServiceImpl(clientRepository: Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LocationsRepository>()) {
      Get.lazyPut<LocationsRepository>(
        LocationsRepositoryImpl.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<LocationsService>()) {
      Get.lazyPut<LocationsService>(
        () => LocationsServiceImpl(repo: Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<EquipmentsRepository>()) {
      Get.lazyPut<EquipmentsRepository>(
        EquipmentsRepositoryImpl.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<EquipmentsService>()) {
      Get.lazyPut<EquipmentsService>(
        () => EquipmentsServiceImpl(repo: Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<OrderLabelService>()) {
      Get.lazyPut<OrderLabelService>(
        () => OrderLabelService(
          clientService: Get.find(),
          locationsService: Get.find(),
          equipmentsService: Get.find(),
          inventoryService: Get.find(),
        ),
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
    Get.put(
      OrderDetailController(
        orderId: orderId,
        service: Get.find<OrdersService>(),
        labelService: Get.find<OrderLabelService>(),
        inventoryService:
            Get.isRegistered<InventoryService>()
                ? Get.find<InventoryService>()
                : null,
        ordersController:
            Get.isRegistered<OrdersController>()
                ? Get.find<OrdersController>()
                : null,
        usersService:
            Get.isRegistered<UsersService>() ? Get.find<UsersService>() : null,
      ),
    );
  }
}
