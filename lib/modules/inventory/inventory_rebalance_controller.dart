import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/inventory_rebalance_model.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:get/get.dart';

class InventoryRebalanceController extends GetxController
    with LoaderMixin, MessagesMixin {
  InventoryRebalanceController({required InventoryService service})
      : _service = service;

  final InventoryService _service;
  final RxBool isLoading = false.obs;
  final RxList<InventoryRebalanceSuggestion> suggestions =
      <InventoryRebalanceSuggestion>[].obs;
  final RxInt days = 30.obs;
  final RxString search = ''.obs;

  @override
  void onInit() {
    loaderListener(isLoading);
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final data = await _service.rebalance(days: days.value);
      suggestions.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }

  void setDays(int value) {
    if (days.value == value) return;
    days.value = value;
    load();
  }

  void setSearch(String value) {
    search.value = value.trim().toLowerCase();
  }

  List<InventoryRebalanceSuggestion> get filteredSuggestions {
    final term = search.value;
    if (term.isEmpty) return suggestions;
    return suggestions
        .where(
          (s) =>
              s.name.toLowerCase().contains(term) ||
              (s.sku ?? '').toLowerCase().contains(term),
        )
        .toList();
  }
}

