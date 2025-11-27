import 'package:air_sync/modules/cost_centers/cost_centers_controller.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';
import 'package:get/get.dart';

class CostCentersBindings implements Bindings {
  @override
  void dependencies() {
    Get.put(
      CostCentersController(service: Get.find<CostCentersService>()),
    );
  }
}
