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

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

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

      isLoading(false);
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back();
      clearForm();

      message(
        MessageModel.success(
          title: 'Sucesso!',
          message: 'Item atualizado com novo registro!',
        ),
      );
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.toString()));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteRecordFromItemByIndex(int index) async {
    isLoading.value = true;

    try {
      // Verifica se o index é válido antes de acessar
      if (index < 0 || index >= item.value.entries.length) {
        throw Exception('Índice inválido');
      }

      // Cria cópia dos registros e remove o desejado
      final updatedEntries = [...item.value.entries];
      final removedEntry = updatedEntries.removeAt(index);

      // Cria nova versão do item com quantidade atualizada
      final updatedItem = item.value.copyWith(
        entries: updatedEntries,
        quantity: item.value.quantity - removedEntry.quantity,
      );

      // Atualiza no banco
      await _itemService.updateItem(updatedItem);

      // Atualiza o item local
      item.value = updatedItem;

      // Atualiza o item na lista geral
      final inventoryController = Get.find<InventoryController>();
      final mainIndex = inventoryController.items.indexWhere(
        (e) => e.id == updatedItem.id,
      );
      if (mainIndex != -1) {
        inventoryController.items[mainIndex] = updatedItem;
      }

      // Aguarda a UI reconstruir antes de seguir
      await Future.delayed(const Duration(milliseconds: 100));
      isLoading(false);

      message(
        MessageModel.success(
          title: 'Sucesso!',
          message: 'Registro removido com sucesso!',
        ),
      );
    } catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.toString()));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteItem() async {
    isLoading.value = true;

    try {
      // Remove do banco de dados
      await _itemService.deleteItem(item.value.id);

      // Remove da lista local
      final inventoryController = Get.find<InventoryController>();
      inventoryController.items.removeWhere((e) => e.id == item.value.id);

      // Fecha a página atual
      isLoading(false);
      Get.back(); // Fecha a tela de histórico
      await Future.delayed(const Duration(milliseconds: 300));

      message(
        MessageModel.success(
          title: 'Item removido',
          message: 'O item foi excluído com sucesso do estoque.',
        ),
      );
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível remover o item: $e',
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  clearForm() {
    quantityToAddCtrl.clear();
  }

  @override
  void onClose() {
    quantityToAddCtrl.dispose();
    super.onClose();
  }
}
