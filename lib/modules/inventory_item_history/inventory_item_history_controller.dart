import 'package:air_sync/models/inventory_model.dart';
import 'package:get/get.dart';

enum InventoryHistoryFilter { all, entries, exits, adjustments }

class InventoryItemHistoryController extends GetxController {
  final isLoading = false.obs;
  final Rxn<InventoryItemModel> item = Rxn<InventoryItemModel>();
  final RxList<StockMovementModel> movements = <StockMovementModel>[].obs;
  final selectedFilter = InventoryHistoryFilter.all.obs;

  late final String _itemId;

  @override
  void onInit() {
    _resolveArguments();
    _hydrateMovementsFromItem();
    super.onInit();
  }

  void _resolveArguments() {
    final args = Get.arguments;
    if (args is InventoryItemModel) {
      item.value = args;
      _itemId = args.id;
      return;
    }
    if (args is Map) {
      if (args['item'] is InventoryItemModel) {
        final InventoryItemModel model = args['item'];
        item.value = model;
        _itemId = model.id;
        return;
      }
      if (args['itemId'] != null) {
        _itemId = args['itemId'].toString();
        return;
      }
    }
    _itemId = args?.toString() ?? '';
  }

  @override
  Future<void> onReady() async {
    await refreshData();
    super.onReady();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    _hydrateMovementsFromItem();
    isLoading.value = false;
  }

  List<StockMovementModel> get filteredMovements {
    final filter = selectedFilter.value;
    return movements.where((movement) {
      switch (filter) {
        case InventoryHistoryFilter.all:
          return true;
        case InventoryHistoryFilter.entries:
          return isEntry(movement.type);
        case InventoryHistoryFilter.exits:
          return isExit(movement.type);
        case InventoryHistoryFilter.adjustments:
          return isAdjustment(movement.type);
      }
    }).toList();
  }

  void changeFilter(InventoryHistoryFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
  }

  bool isEntry(MovementType type) {
    return type == MovementType.receive ||
        type == MovementType.adjustPos ||
        type == MovementType.transferIn ||
        type == MovementType.returnIn;
  }

  bool isExit(MovementType type) {
    return type == MovementType.issue ||
        type == MovementType.adjustNeg ||
        type == MovementType.transferOut;
  }

  bool isAdjustment(MovementType type) {
    return type == MovementType.adjustPos || type == MovementType.adjustNeg;
  }

  String formatQuantity(double value) {
    return (value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2))
        .replaceAll('.', ',');
  }

  String titleForMovement(StockMovementModel movement) {
    switch (movement.type) {
      case MovementType.receive:
        return 'Entrada de compra';
      case MovementType.returnIn:
        return 'Entrada (devolução)';
      case MovementType.transferIn:
        return 'Transferência recebida';
      case MovementType.issue:
        return 'Saída';
      case MovementType.transferOut:
        return 'Transferência enviada';
      case MovementType.adjustPos:
        return 'Ajuste positivo';
      case MovementType.adjustNeg:
        return 'Ajuste negativo';
    }
  }

  String subtitleForMovement(StockMovementModel movement) {
    final parts = <String>[];
    if ((movement.reason ?? '').isNotEmpty) {
      parts.add(movement.reason!);
    }
    if ((movement.documentRef ?? '').isNotEmpty) {
      parts.add('Ref: ${movement.documentRef}');
    }
    if ((movement.performedBy ?? '').isNotEmpty) {
      parts.add('Por: ${movement.performedBy}');
    }
    return parts.isEmpty ? 'Sem detalhes adicionais' : parts.join(' • ');
  }

  void updateItem(InventoryItemModel updated) {
    if (updated.id != _itemId) return;
    item.value = updated;
    _hydrateMovementsFromItem();
  }

  void _hydrateMovementsFromItem() {
    final source = item.value;
    if (source == null) {
      movements.clear();
      return;
    }
    final list = [...source.movements];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    movements.assignAll(list);
  }
}
