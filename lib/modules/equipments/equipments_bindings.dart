import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/equipments/equipments_service_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:get/get.dart';

import 'equipments_controller.dart';

class EquipmentsBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EquipmentsRepository>(() => EquipmentsRepositoryImpl());
    Get.lazyPut<EquipmentsService>(() => EquipmentsServiceImpl(repo: Get.find()));
    Get.lazyPut<LocationsRepository>(() => LocationsRepositoryImpl(), fenix: true);
    Get.lazyPut<LocationsService>(() => LocationsServiceImpl(repo: Get.find()), fenix: true);
    Get.put(EquipmentsController(service: Get.find()));
  }
}

