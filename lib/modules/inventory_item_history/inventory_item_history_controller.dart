import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/inventory_entry_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class InventoryItemHistoryController extends GetxController
    with MessagesMixin, LoaderMixin {
  final InventoryService _itemService;

  InventoryItemHistoryController({required InventoryService inventoryService})
    : _itemService = inventoryService;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final Rx<InventoryItemModel> item = (Get.arguments as InventoryItemModel).obs;

  final quantityToAddCtrl = TextEditingController();

  Future<void> addRecordToItem() async {
    isLoading.value = true;

    try {
      // Cria novo registro
      final newRecord = InventoryEntryModel(
        date: DateTime.now(),
        quantity: double.parse(quantityToAddCtrl.text),
      );

      // Cria nova versão do item com a quantidade somada e o registro adicionado
      item.value = item.value.copyWith(
        quantity: item.value.quantity + double.parse(quantityToAddCtrl.text),
        entries: [...item.value.entries, newRecord],
      );

      // Atualiza no banco de dados
      await _itemService.updateItem(item.value);

      // Atualiza na lista local (se necessário)
      final inventoryController = Get.find<InventoryController>();
      final index = inventoryController.items.indexWhere(
        (e) => e.id == item.value.id,
      );
      if (index != -1) {
        inventoryController.items[index] = item.value;
      }

      message(
        MessageModel.info(
          title: 'Sucesso',
          message: 'Item atualizado com novo registro!',
        ),
      );
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.toString()));
    } finally {
      isLoading.value = false;
    }
  }
}
