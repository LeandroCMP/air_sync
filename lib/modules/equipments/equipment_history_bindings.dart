import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/repositories/users/users_repository.dart';
import 'package:air_sync/repositories/users/users_repository_impl.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/equipments/equipments_service_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:air_sync/repositories/maintenance/maintenance_repository.dart';
import 'package:air_sync/repositories/maintenance/maintenance_repository_impl.dart';
import 'package:air_sync/services/maintenance/maintenance_service.dart';
import 'package:air_sync/services/maintenance/maintenance_service_impl.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:air_sync/services/users/users_service_impl.dart';
import 'package:get/get.dart';
import 'equipment_history_controller.dart';

class EquipmentHistoryBindings implements Bindings {
  @override
  void dependencies() {
    // Garante dependências quando a tela é aberta fora do fluxo de equipamentos
    if (!Get.isRegistered<EquipmentsRepository>()) {
      Get.lazyPut<EquipmentsRepository>(
        () => EquipmentsRepositoryImpl(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<EquipmentsService>()) {
      Get.lazyPut<EquipmentsService>(
        () => EquipmentsServiceImpl(repo: Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LocationsRepository>()) {
      Get.lazyPut<LocationsRepository>(
        () => LocationsRepositoryImpl(),
        fenix: true,
      );
    }
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

    OrdersService? ordersService;
    if (Get.isRegistered<OrdersService>()) {
      ordersService = Get.find<OrdersService>();
    }
    UsersService? usersService;
    if (Get.isRegistered<UsersService>()) {
      usersService = Get.find<UsersService>();
    }

    Get.lazyPut<EquipmentHistoryController>(
      () => EquipmentHistoryController(
        service: Get.find<EquipmentsService>(),
        ordersService: ordersService,
        usersService: usersService,
        maintenanceService:
            Get.isRegistered<MaintenanceService>()
                ? Get.find<MaintenanceService>()
                : null,
      ),
      fenix: true,
    );
  }
}
