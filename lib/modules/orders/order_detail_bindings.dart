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
import 'package:air_sync/repositories/purchases/purchases_repository.dart';
import 'package:air_sync/repositories/purchases/purchases_repository_impl.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';
import 'package:air_sync/services/purchases/purchases_service_impl.dart';
import 'package:air_sync/repositories/maintenance/maintenance_repository.dart';
import 'package:air_sync/repositories/maintenance/maintenance_repository_impl.dart';
import 'package:air_sync/services/maintenance/maintenance_service.dart';
import 'package:air_sync/services/maintenance/maintenance_service_impl.dart';
import 'package:air_sync/repositories/users/users_repository.dart';
import 'package:air_sync/repositories/users/users_repository_impl.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:air_sync/services/users/users_service_impl.dart';
import 'package:air_sync/modules/orders/orders_controller.dart';
import 'package:air_sync/repositories/company_profile/company_profile_repository.dart';
import 'package:air_sync/repositories/company_profile/company_profile_repository_impl.dart';
import 'package:air_sync/services/company_profile/company_profile_service.dart';
import 'package:air_sync/services/company_profile/company_profile_service_impl.dart';
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
      if (!Get.isRegistered<PurchasesRepository>()) {
        Get.lazyPut<PurchasesRepository>(
          () => PurchasesRepositoryImpl(),
          fenix: true,
        );
      }
      if (!Get.isRegistered<PurchasesService>()) {
        Get.lazyPut<PurchasesService>(
          () => PurchasesServiceImpl(repo: Get.find()),
          fenix: true,
        );
      }
      Get.lazyPut<OrdersService>(
        () => OrdersServiceImpl(
          repo: Get.find(),
          purchasesService:
              Get.isRegistered<PurchasesService>() ? Get.find<PurchasesService>() : null,
        ),
      );
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
    if (!Get.isRegistered<CompanyProfileRepository>()) {
      Get.lazyPut<CompanyProfileRepository>(
        CompanyProfileRepositoryImpl.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<CompanyProfileService>()) {
      Get.lazyPut<CompanyProfileService>(
        () => CompanyProfileServiceImpl(repository: Get.find()),
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
    if (!Get.isRegistered<MaintenanceRepository>()) {
      Get.lazyPut<MaintenanceRepository>(
        () => MaintenanceRepositoryImpl(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<MaintenanceService>()) {
      Get.lazyPut<MaintenanceService>(
        () => MaintenanceServiceImpl(repository: Get.find()),
        fenix: true,
      );
    }
    Get.put(
      OrderDetailController(
        orderId: orderId,
        service: Get.find<OrdersService>(),
        labelService:
            Get.isRegistered<OrderLabelService>()
                ? Get.find<OrderLabelService>()
                : null,
        inventoryService:
            Get.isRegistered<InventoryService>()
                ? Get.find<InventoryService>()
                : null,
        clientService:
            Get.isRegistered<ClientService>()
                ? Get.find<ClientService>()
                : null,
        locationsService:
            Get.isRegistered<LocationsService>()
                ? Get.find<LocationsService>()
                : null,
        equipmentsService:
            Get.isRegistered<EquipmentsService>()
                ? Get.find<EquipmentsService>()
                : null,
        maintenanceService:
            Get.isRegistered<MaintenanceService>()
                ? Get.find<MaintenanceService>()
                : null,
        companyProfileService:
            Get.isRegistered<CompanyProfileService>()
                ? Get.find<CompanyProfileService>()
                : null,
        usersService:
            Get.isRegistered<UsersService>()
                ? Get.find<UsersService>()
                : null,
        ordersController:
            Get.isRegistered<OrdersController>()
                ? Get.find<OrdersController>()
                : null,
      ),
    );
  }
}
