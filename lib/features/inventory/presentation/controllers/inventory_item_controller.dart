import 'package:get/get.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/usecases/get_inventory_item_usecase.dart';
import '../../domain/usecases/move_inventory_usecase.dart';

class InventoryItemController extends GetxController {
  InventoryItemController(this._getItemUseCase, this._moveUseCase);

  final GetInventoryItemUseCase _getItemUseCase;
  final MoveInventoryUseCase _moveUseCase;

  final item = Rxn<InventoryItem>();
  final isLoading = false.obs;

  Future<void> load(String id) async {
    isLoading.value = true;
    final result = await _getItemUseCase.call(id);
    isLoading.value = false;
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => item.value = data,
    );
  }

  Future<void> move(Map<String, dynamic> payload) async {
    final result = await _moveUseCase.call(payload);
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) => Get.snackbar('Sucesso', 'Movimentação registrada'),
    );
  }
}
