import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:get/get.dart';

enum InventoryHistoryFilter { all, entries, exits, adjustments }

class InventoryItemHistoryController extends GetxController {
  InventoryItemHistoryController({required InventoryService inventoryService})
    : _inventoryService = inventoryService;

  final InventoryService _inventoryService;

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
    if (_itemId.isEmpty) {
      _hydrateMovementsFromItem();
      return;
    }

    isLoading.value = true;
    try {
      final freshItem = await _inventoryService.getItem(_itemId);
      item.value = freshItem;
      final fetchedMovements = await _inventoryService.listMovements(
        itemId: _itemId,
        limit: 200,
      );
      movements.assignAll(_sortMovements(fetchedMovements));
    } catch (_) {
      _hydrateMovementsFromItem();
    } finally {
      isLoading.value = false;
    }
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
        return 'Entrada (devolucao)';
      case MovementType.transferIn:
        return 'Transferencia recebida';
      case MovementType.issue:
        return 'Saida';
      case MovementType.transferOut:
        return 'Transferencia enviada';
      case MovementType.adjustPos:
        return 'Ajuste positivo';
      case MovementType.adjustNeg:
        return 'Ajuste negativo';
    }
  }

  String subtitleForMovement(StockMovementModel movement) {
    final parts = <String>[];
    final unit = item.value?.unit ?? '';
    final qtyLabel =
        unit.trim().isEmpty
            ? formatQuantity(movement.quantity)
            : '${formatQuantity(movement.quantity)} $unit';
    parts.add('Qtd.: $qtyLabel');

    final reason = (movement.reason ?? '').trim();
    if (reason.isNotEmpty) {
      parts.add(reason);
    }

    final document = (movement.documentRef ?? '').trim();
    if (document.isNotEmpty) {
      parts.add('Ref: $document');
    }

    final performer = (movement.performedBy ?? '').trim();
    if (performer.isNotEmpty) {
      parts.add('Por: $performer');
    }

    parts.add('Registro: ${_formatDateTime(movement.createdAt)}');

    return parts.join(' • ');
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
    movements.assignAll(_sortMovements(source.movements));
  }

  List<StockMovementModel> _sortMovements(List<StockMovementModel> source) {
    final list = List<StockMovementModel>.from(source);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString().padLeft(4, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
