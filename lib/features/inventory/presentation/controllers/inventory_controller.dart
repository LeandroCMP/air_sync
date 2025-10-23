import 'package:get/get.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/get_low_stock_usecase.dart';

class InventoryController extends GetxController {
  InventoryController(this._getItemsUseCase, this._getLowStockUseCase);

  final GetInventoryItemsUseCase _getItemsUseCase;
  final GetLowStockUseCase _getLowStockUseCase;

  final items = <InventoryItem>[].obs;
  final lowStockItems = <InventoryItem>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final result = await _getItemsUseCase.call();
    final lowStockResult = await _getLowStockUseCase.call();
    isLoading.value = false;
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => items.assignAll(data),
    );
    lowStockResult.fold(
      (failure) => Get.log('low stock error: ${failure.message}'),
      (data) => lowStockItems.assignAll(data),
    );
  }
}
