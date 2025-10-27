import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/repositories/locations/locations_repository_impl.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/locations/locations_service_impl.dart';
import 'package:get/get.dart';
import 'locations_controller.dart';

class LocationsBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationsRepository>(() => LocationsRepositoryImpl());
    Get.lazyPut<LocationsService>(() => LocationsServiceImpl(repo: Get.find()));
    Get.put(LocationsController(service: Get.find()));
  }
}

