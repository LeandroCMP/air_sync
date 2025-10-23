import 'package:get/get.dart';

import '../../domain/usecases/get_inventory_item_usecase.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/get_low_stock_usecase.dart';
import '../../domain/usecases/move_inventory_usecase.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/inventory_item_controller.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryController>(() => InventoryController(Get.find<GetInventoryItemsUseCase>(), Get.find<GetLowStockUseCase>()));
    Get.lazyPut<InventoryItemController>(() => InventoryItemController(
          Get.find<GetInventoryItemUseCase>(),
          Get.find<MoveInventoryUseCase>(),
        ));
  }
}
