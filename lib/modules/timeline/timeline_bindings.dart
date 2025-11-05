import 'package:air_sync/repositories/timeline/timeline_repository.dart';
import 'package:air_sync/repositories/timeline/timeline_repository_impl.dart';
import 'package:air_sync/services/timeline/timeline_service.dart';
import 'package:air_sync/services/timeline/timeline_service_impl.dart';
import 'package:get/get.dart';

import 'timeline_controller.dart';

class TimelineBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimelineRepository>(() => TimelineRepositoryImpl());
    Get.lazyPut<TimelineService>(() => TimelineServiceImpl(repo: Get.find()));
    Get.put(TimelineController(service: Get.find()));
  }
}


