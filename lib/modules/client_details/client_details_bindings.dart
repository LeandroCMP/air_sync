import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/repositories/orders/orders_repository.dart';
import 'package:air_sync/repositories/orders/orders_repository_impl.dart';
import 'package:air_sync/repositories/users/users_repository.dart';
import 'package:air_sync/repositories/users/users_repository_impl.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/equipments/equipments_service_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/orders/orders_service_impl.dart';
import 'package:air_sync/repositories/purchases/purchases_repository.dart';
import 'package:air_sync/repositories/purchases/purchases_repository_impl.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';
import 'package:air_sync/services/purchases/purchases_service_impl.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:air_sync/services/users/users_service_impl.dart';
import 'package:get/get.dart';

import './client_details_controller.dart';

class ClientDetailsBindings implements Bindings {
  @override
  void dependencies() {
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
      ClientDetailsController(
        clientService: Get.find(),
        locationsService: Get.find(),
        equipmentsService: Get.find(),
        ordersService: Get.find<OrdersService>(),
        usersService: Get.find<UsersService>(),
      ),
    );
  }
}
