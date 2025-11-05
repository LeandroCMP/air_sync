import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/equipments/equipments_service_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:get/get.dart';
import 'equipment_history_controller.dart';

class EquipmentHistoryBindings implements Bindings {
  @override
  void dependencies() {
    // Garante dependências quando a tela é aberta fora do fluxo de equipamentos
    if (!Get.isRegistered<EquipmentsRepository>()) {
      Get.lazyPut<EquipmentsRepository>(() => EquipmentsRepositoryImpl(), fenix: true);
    }
    if (!Get.isRegistered<EquipmentsService>()) {
      Get.lazyPut<EquipmentsService>(() => EquipmentsServiceImpl(repo: Get.find()), fenix: true);
    }
    if (!Get.isRegistered<LocationsRepository>()) {
      Get.lazyPut<LocationsRepository>(() => LocationsRepositoryImpl(), fenix: true);
    }
    if (!Get.isRegistered<LocationsService>()) {
      Get.lazyPut<LocationsService>(() => LocationsServiceImpl(repo: Get.find()), fenix: true);
    }

    Get.lazyPut<EquipmentHistoryController>(() => EquipmentHistoryController(service: Get.find<EquipmentsService>()), fenix: true);
  }
}
