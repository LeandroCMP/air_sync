import 'package:get/get.dart';
import './inventory_item_history_controller.dart';

class InventoryItemHistoryBindings implements Bindings {
  @override
  void dependencies() {
    Get.put(InventoryItemHistoryController());
  }
}
