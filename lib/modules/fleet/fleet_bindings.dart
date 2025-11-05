import 'package:air_sync/repositories/fleet/fleet_repository.dart';
import 'package:air_sync/repositories/fleet/fleet_repository_impl.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';
import 'package:air_sync/services/fleet/fleet_service_impl.dart';
import 'package:get/get.dart';

import 'fleet_controller.dart';

class FleetBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FleetRepository>(() => FleetRepositoryImpl());
    Get.lazyPut<FleetService>(() => FleetServiceImpl(repo: Get.find()));
    Get.put(FleetController(service: Get.find()));
  }
}


