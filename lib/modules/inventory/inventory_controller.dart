import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController
    with LoaderMixin, MessagesMixin {
  final AuthServiceApplication _authServiceApplication;
  final InventoryService _itemService;

  InventoryController({
    required AuthServiceApplication authServiceApplication,
    required InventoryService inventoryService,
  }) : _authServiceApplication = authServiceApplication,
       _itemService = inventoryService;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final RxList<InventoryItemModel> items = <InventoryItemModel>[].obs;

  final descriptionController = TextEditingController();
  final unitController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await getItems();
    super.onReady();
  }

  Future<void> getItems() async {
    isLoading.value = true;
    try {
      final result = await _itemService.getItems(
        _authServiceApplication.user.value!.id,
      );
      items.assignAll(result);
    } catch (e) {
      Get.snackbar('Erro', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerItem() async {
  isLoading.value = true;

  try {
    final description = descriptionController.text.trim();
    final unit = unitController.text.trim();
    final quantityText = quantityController.text.trim();

    final quantity = double.tryParse(quantityText.replaceAll(',', '.'));

    if (quantity == null || quantity <= 0) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: 'Quantidade inválida.',
        ),
      );
      return;
    }

    final item = InventoryItemModel(
      id: '',
      userId: _authServiceApplication.user.value!.id,
      description: description.toUpperCase().trim(),
      unit: unit.toUpperCase().trim(),
      quantity: quantity,
    );
    final savedItem =  await _itemService.registerItem(item);

    items.add(savedItem);

    isLoading(false);
    await Future.delayed(const Duration(milliseconds: 300));
    Get.back(); 

    message(
      MessageModel.success(
        title: 'Sucesso!',
        message: 'Item cadastrado com sucesso!',
      ),
    );

    clearForm();
  } catch (e) {
    message(
      MessageModel.error(
        title: 'Erro!',
        message: 'Erro inesperado ao registrar o item.',
      ),
    );
  } finally {
    isLoading.value = false;
  }
}

  
  void clearForm() {
    descriptionController.clear();
    unitController.clear();
    quantityController.clear();
  }

  
  @override
  void onClose() {
    descriptionController.dispose();
    unitController.dispose();
    quantityController.dispose();
    super.onClose();
  }
}
