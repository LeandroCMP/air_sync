import 'package:get/get.dart';

import '../../domain/usecases/process_sync_queue_usecase.dart';
import '../../domain/usecases/sync_now_usecase.dart';
import '../controllers/sync_controller.dart';

class SyncBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SyncController>()) {
      Get.lazyPut<SyncController>(() => SyncController(Get.find<SyncNowUseCase>(), Get.find<ProcessSyncQueueUseCase>()));
    }
  }
}
