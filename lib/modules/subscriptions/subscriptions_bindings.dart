import 'package:air_sync/modules/subscriptions/subscriptions_controller.dart';
import 'package:air_sync/services/subscriptions/subscriptions_service.dart';
import 'package:get/get.dart';

class SubscriptionsBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SubscriptionsController(
        service: Get.find<SubscriptionsService>(),
        auth: Get.find(),
      ),
    );
  }
}
