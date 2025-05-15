import 'package:get/get.dart';
import './client_details_controller.dart';

class ClientDetailsBindings implements Bindings {
    @override
    void dependencies() {
        Get.put(ClientDetailsController(
          clientService: Get.find(),
        ));
    }
}