import 'dart:async';
import 'package:air_sync/application/core/errors/inventory_failure.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/modules/inventory_item_history/inventory_item_history_controller.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryController extends GetxController
    with LoaderMixin, MessagesMixin {
  final InventoryService _itemService;

  InventoryController({
    required InventoryService inventoryService,
  }) : _itemService = inventoryService;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final RxList<InventoryItemModel> items = <InventoryItemModel>[].obs;

  // Controle interno de sincronização com a API
  bool _needsRefresh = true;
  bool _refreshInProgress = false;
  Timer? _deferredRefresh;

  // Controles de formulário
  final descriptionController = TextEditingController(); // name
  final skuController = TextEditingController(); // sku
  final unitController = TextEditingController(); // unit (un|lt|kg)
  final minStockController = TextEditingController(); // minQty
  final quantityController =
      TextEditingController(); // quantidade inicial (opcional)
  final searchController = TextEditingController();
  final RxString searchTerm = ''.obs;
  Timer? _searchDebounce;

  // Campos opcionais dedicados
  final maxQtyController = TextEditingController(); // maxQty
  final supplierIdController = TextEditingController(); // supplierId
  final costController = TextEditingController(); // avgCost
  final sellPriceController = TextEditingController(); // sellPrice

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

  Future<void> getItems({bool showLoader = true}) async {
    if (showLoader) {
      isLoading.value = true;
    }
    try {
      final q = searchTerm.value.trim();
      final result = await _itemService.listItems(q: q.isEmpty ? null : q);
      final currentMovements = {
        for (final existing in items) existing.id: existing.movements,
      };
      final merged =
          result.map((item) {
            final localMovements = currentMovements[item.id];
            if (localMovements == null || localMovements.isEmpty) {
              return item;
            }
            final combined = [...localMovements];
            combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return item.copyWith(movements: combined);
          }).toList();
      items.assignAll(merged);
      _needsRefresh = false;
      _deferredRefresh?.cancel();
    } catch (e) {
      Get.snackbar('Erro', e.toString());
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
      _refreshInProgress = false;
    }
  }

  Future<void> refreshCurrentView({bool showLoader = false}) async {
    await getItems(showLoader: showLoader);
  }

  Future<void> registerItem() async {
    final name = descriptionController.text.trim();
    final sku = skuController.text.trim();
    final unit =
        unitController.text.trim().isEmpty ? 'un' : unitController.text.trim();
    final minQtyParsed = double.tryParse(
      minStockController.text.replaceAll(',', '.'),
    );
    final minQty =
        (minQtyParsed == null || minQtyParsed < 0) ? 0.0 : minQtyParsed.toDouble();

    if (name.isEmpty) {
      message(
        MessageModel.error(title: 'Erro!', message: 'Informe o nome do item'),
      );
      return;
    }

    isLoading.value = true;
    MessageModel? belowMinimumAlert;
    try {
      final maxQty = double.tryParse(
        maxQtyController.text.replaceAll(',', '.'),
      );
      final avgCost = double.tryParse(costController.text.replaceAll(',', '.'));
      final sellPrice = double.tryParse(
        sellPriceController.text.replaceAll(',', '.'),
      );
      final supplierId =
          supplierIdController.text.trim().isEmpty
              ? null
              : supplierIdController.text.trim();

      final savedItem = await _itemService.registerItem(
        name: name,
        sku: sku,
        minQty: minQty,
        unit: unit,
        maxQty: maxQty,
        supplierId: supplierId,
        avgCost: avgCost,
        sellPrice: sellPrice,
      );

      final initialQty = double.tryParse(
        quantityController.text.replaceAll(',', '.'),
      );

      if (initialQty != null && initialQty > 0) {
        try {
          await _itemService.addRecord(
            itemId: savedItem.id,
            quantityToAdd: initialQty,
          );
        } catch (e) {
          belowMinimumAlert = MessageModel.info(
            title: 'Estoque',
            message:
                'Item criado, mas não foi possível registrar a entrada inicial (${initialQty.toStringAsFixed(2)} ${savedItem.unit}). ${_friendlyError(e, 'Registre manualmente no histórico.')}',
          );
        }
      }

      items.add(savedItem);
      clearForm();
      isLoading.value = false;
      _needsRefresh = false;
      await getItems(showLoader: false);
      message(
        MessageModel.success(
          title: 'Sucesso!',
          message: 'Item cadastrado com sucesso!',
        ),
      );
      if (belowMinimumAlert != null) {
        message(belowMinimumAlert);
      }
    } catch (e) {
      isLoading.value = false;
      message(
        MessageModel.error(
          title: 'Erro!',
          message: _friendlyError(e, 'Erro inesperado ao registrar o item.'),
        ),
      );
    }
  }

  Future<bool> updateItem({
    required InventoryItemModel original,
    required InventoryItemModel updated,
  }) async {
    final trimmedName = updated.description.trim();
    final trimmedSku = updated.sku.trim();
    if (trimmedSku.isNotEmpty &&
        trimmedSku.toUpperCase() != original.sku.trim().toUpperCase()) {
      message(
        MessageModel.error(
          title: 'Estoque',
          message: 'O SKU não pode ser alterado por este fluxo.',
        ),
      );
      return false;
    }
    final trimmedUnit =
        updated.unit.trim().isEmpty ? original.unit : updated.unit.trim();

    String? normalizeOptional(String? value) {
      final textValue = value?.trim();
      if (textValue == null || textValue.isEmpty) return null;
      return textValue;
    }

    final nameChanged =
        trimmedName.isNotEmpty && trimmedName != original.description.trim();
    final unitChanged =
        trimmedUnit.toUpperCase() != original.unit.trim().toUpperCase();
    final minChanged =
        (updated.minQuantity - original.minQuantity).abs() > 0.0001;
    final activeChanged = updated.active != original.active;

    final supplierNew = normalizeOptional(updated.supplierId);
    final supplierOld = normalizeOptional(original.supplierId);
    final supplierChanged = supplierNew != null && supplierNew != supplierOld;

    final maxChanged =
        updated.maxQuantity != null &&
        _doubleChanged(updated.maxQuantity, original.maxQuantity);
    final avgCostChanged =
        updated.avgCost != null &&
        _doubleChanged(updated.avgCost, original.avgCost);
    final sellPriceChanged =
        updated.sellPrice != null &&
        _doubleChanged(updated.sellPrice, original.sellPrice);

    final changes = <String, dynamic>{};
    if (nameChanged) changes['name'] = trimmedName;
    if (unitChanged) changes['unit'] = trimmedUnit.toLowerCase();
    if (minChanged) changes['minQty'] = updated.minQuantity;
    if (activeChanged) changes['active'] = updated.active;
    if (supplierChanged) changes['supplierId'] = supplierNew;
    if (maxChanged) changes['maxQty'] = updated.maxQuantity;
    if (avgCostChanged) changes['avgCost'] = updated.avgCost;
    if (sellPriceChanged) changes['sellPrice'] = updated.sellPrice;

    if (changes.isEmpty) {
      message(
        MessageModel.info(
          title: 'Estoque',
          message: 'Nenhuma alteração para salvar.',
        ),
      );
      return true;
    }

    isLoading.value = true;
    try {
      await _itemService.patchItem(original.id, changes);
      await getItems(showLoader: false);
      message(
        MessageModel.success(
          title: 'Estoque',
          message: 'Item atualizado com sucesso',
        ),
      );
      return true;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: _friendlyError(e, 'Falha ao atualizar o item.'),
        ),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<InventoryItemModel?> zeroItemStock(InventoryItemModel item) async {
    if (item.quantity <= 0) {
      message(
        MessageModel.info(
          title: 'Estoque',
          message: 'O item ${item.description} já está com estoque zerado.',
        ),
      );
      return item;
    }

    isLoading.value = true;
    try {
      await _itemService.createMovement(
        itemId: item.id,
        quantity: item.quantity,
        type: MovementType.adjustNeg,
        reason: 'Zerar estoque para exclusão',
      );

      InventoryItemModel refreshed;
      try {
        refreshed = await _itemService.getItem(item.id);
      } catch (_) {
        refreshed = item.copyWith(quantity: 0);
      }

      final index = items.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        items[index] = refreshed;
      }

      message(
        MessageModel.success(
          title: 'Estoque',
          message: 'Estoque zerado com sucesso.',
        ),
      );
      await getItems(showLoader: false);
      return refreshed;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Estoque',
          message: _friendlyError(e, 'Falha ao zerar o estoque.'),
        ),
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteItem(String id) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1 && items[index].quantity > 0) {
      message(
        MessageModel.info(
          title: 'Estoque',
          message:
              'Zere o estoque do item antes de excluir. Abra a edição do item e ajuste a quantidade para zero.',
        ),
      );
      return false;
    }
    isLoading.value = true;
    try {
      await _itemService.deleteItem(id);
      items.removeWhere((e) => e.id == id);
      _needsRefresh = true;
      message(
        MessageModel.success(
          title: 'Estoque',
          message: 'Item excluído com sucesso',
        ),
      );
      return true;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: _friendlyError(e, 'Falha ao excluir o item.'),
        ),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyError(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return (data['message'] as String).trim();
      }
      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    }
    if (error is InventoryFailure) {
      final cleaned =
          error.message.replaceFirst(RegExp(r'^\[[A-Z_]+\]\s*'), '').trim();
      if (cleaned.toLowerCase() == 'erro de valida??o') {
        return '$cleaned. Confira unidade e quantidade m?nima.';
      }
      return cleaned.isEmpty ? fallback : cleaned;
    }
    return fallback;
  }

  void clearForm() {
    descriptionController.clear();
    skuController.clear();
    unitController.clear();
    minStockController.clear();
    quantityController.clear();
    maxQtyController.clear();
    supplierIdController.clear();
    costController.clear();
    sellPriceController.clear();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    skuController.dispose();
    unitController.dispose();
    minStockController.dispose();
    quantityController.dispose();
    maxQtyController.dispose();
    supplierIdController.dispose();
    costController.dispose();
    sellPriceController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
    _deferredRefresh?.cancel();
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    searchTerm.value = normalized;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      getItems(showLoader: true);
    });
  }

  void ensureLatestData({bool showLoader = false}) {
    if (!_needsRefresh || _refreshInProgress) return;
    _refreshInProgress = true;
    getItems(showLoader: showLoader);
  }

  void scheduleRefresh({
    Duration delay = Duration.zero,
    bool showLoader = false,
  }) {
    _needsRefresh = true;
    _deferredRefresh?.cancel();
    if (delay == Duration.zero) {
      ensureLatestData(showLoader: showLoader);
    } else {
      _deferredRefresh = Timer(delay, () {
        ensureLatestData(showLoader: showLoader);
      });
    }
  }

  void registerLocalMovement({
    required String itemId,
    required double quantity,
    required MovementType type,
    String? reason,
    String? documentRef,
  }) {
    final index = items.indexWhere((element) => element.id == itemId);
    if (index == -1) return;

    final current = items[index];
    final movement = StockMovementModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      itemId: itemId,
      locationId: null,
      quantity: quantity,
      type: type,
      reason: reason,
      documentRef: documentRef,
      idempotencyKey: null,
      performedBy: null,
      createdAt: DateTime.now(),
    );

    final updatedMovements = [movement, ...current.movements];
    final updatedItem = current.copyWith(movements: updatedMovements);
    items[index] = updatedItem;
    items.refresh();

    if (Get.isRegistered<InventoryItemHistoryController>()) {
      Get.find<InventoryItemHistoryController>().updateItem(updatedItem);
    }
  }

  bool _doubleChanged(double? newValue, double? oldValue) {
    if (newValue == null && oldValue == null) return false;
    if (newValue == null || oldValue == null) return true;
    return (newValue - oldValue).abs() > 0.0001;
  }
}
