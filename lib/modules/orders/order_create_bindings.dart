import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/repositories/client/client_repository_impl.dart';
import 'package:air_sync/repositories/cost_centers/cost_centers_repository.dart';
import 'package:air_sync/repositories/cost_centers/cost_centers_repository_impl.dart';
import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/repositories/inventory/inventory_repository_impl.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/repositories/orders/orders_repository_impl.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/client/client_service_impl.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service_impl.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/equipments/equipments_service_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/inventory/inventory_service_impl.dart';
import 'package:air_sync/repositories/users/users_repository.dart';
import 'package:air_sync/repositories/users/users_repository_impl.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/orders/orders_service_impl.dart';
import 'package:air_sync/repositories/purchases/purchases_repository.dart';
import 'package:air_sync/repositories/purchases/purchases_repository_impl.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';
import 'package:air_sync/services/purchases/purchases_service_impl.dart';
import 'package:air_sync/services/orders/order_label_service.dart';
import 'package:air_sync/models/order_draft_model.dart';
import 'package:air_sync/services/orders/order_draft_storage.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:air_sync/services/users/users_service_impl.dart';
import 'package:get/get.dart';

import 'order_create_controller.dart';

class OrderCreateBindings implements Bindings {
  OrderCreateBindings({this.initialDraft});

  final OrderDraftModel? initialDraft;

  @override
  void dependencies() {
    if (!Get.isRegistered<OrdersRepository>()) {
      Get.lazyPut<OrdersRepository>(() => OrdersRepositoryImpl(), fenix: true);
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

    if (!Get.isRegistered<UsersRepository>()) {
      Get.lazyPut<UsersRepository>(() => UsersRepositoryImpl(), fenix: true);
    }
    if (!Get.isRegistered<UsersService>()) {
      Get.lazyPut<UsersService>(
        () => UsersServiceImpl(repository: Get.find()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<CostCentersRepository>()) {
      Get.lazyPut<CostCentersRepository>(
        CostCentersRepositoryImpl.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<CostCentersService>()) {
      Get.lazyPut<CostCentersService>(
        () => CostCentersServiceImpl(repository: Get.find()),
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

    if (!Get.isRegistered<OrderDraftStorage>()) {
      Get.lazyPut<OrderDraftStorage>(OrderDraftStorage.new, fenix: true);
    }

    Get.put(
      OrderCreateController(
        ordersService: Get.find(),
        clientService: Get.find(),
        locationsService: Get.find(),
        equipmentsService: Get.find(),
        inventoryService: Get.find(),
        labelService: Get.find(),
        usersService: Get.find(),
        costCentersService: Get.find(),
        draftStorage: Get.find(),
        initialDraft: initialDraft,
      ),
    );
  }
}
