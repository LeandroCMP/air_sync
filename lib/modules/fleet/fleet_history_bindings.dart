import 'package:air_sync/modules/fleet/fleet_history_controller.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';
import 'package:get/get.dart';

class FleetHistoryBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FleetHistoryController(fleetService: Get.find<FleetService>()),
    );
  }
}
