import 'package:get/get.dart';

import '../../../sync/domain/usecases/process_sync_queue_usecase.dart';
import '../../../sync/domain/usecases/sync_now_usecase.dart';
import '../../../sync/presentation/controllers/sync_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SyncController>(() => SyncController(Get.find<SyncNowUseCase>(), Get.find<ProcessSyncQueueUseCase>()));
  }
}
