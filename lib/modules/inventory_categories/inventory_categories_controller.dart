import 'dart:async';

import 'package:air_sync/models/inventory_category_model.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:get/get.dart';

class InventoryCategoriesController extends GetxController {
  InventoryCategoriesController({required InventoryService service})
    : _service = service;

  final InventoryService _service;

  final RxList<InventoryCategoryModel> categories =
      <InventoryCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchTerm = ''.obs;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final query = searchTerm.value.trim();
      final items = await _service.listCategories(
        search: query.isEmpty ? null : query,
      );
      categories.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchTerm.value = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<bool> saveCategory({
    InventoryCategoryModel? original,
    required String name,
    required double markupPercent,
    String? description,
  }) async {
    try {
      if (original == null) {
        await _service.createCategory(
          name: name,
          markupPercent: markupPercent,
          description: description,
        );
      } else {
        await _service.updateCategory(
          id: original.id,
          name: name,
          markupPercent: markupPercent,
          description: description,
        );
      }
      await load();
      Get.snackbar(
        'Categorias',
        original == null ? 'Categoria criada' : 'Categoria atualizada',
      );
      return true;
    } catch (_) {
      Get.snackbar('Categorias', 'Não foi possível salvar a categoria');
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _service.deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      Get.snackbar('Categorias', 'Categoria removida');
      return true;
    } catch (_) {
      Get.snackbar('Categorias', 'Falha ao remover a categoria');
      return false;
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
