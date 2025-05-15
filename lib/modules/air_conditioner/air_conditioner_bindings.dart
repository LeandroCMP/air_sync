import 'package:get/get.dart';
import './air_conditioner_controller.dart';

class AirConditionerBindings implements Bindings {
    @override
    void dependencies() {
        Get.put(AirConditionerController());
    }
}