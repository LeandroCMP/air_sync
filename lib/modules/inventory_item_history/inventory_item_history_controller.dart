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
  final RxList<InventoryCostHistoryEntry> costHistory =
      <InventoryCostHistoryEntry>[].obs;
  final selectedFilter = InventoryHistoryFilter.all.obs;
  final RxInt yearFilter = DateTime.now().year.obs;
  final RxnInt monthFilter = RxnInt();

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
      await _loadCostHistory(freshItem);
      _syncFiltersWithData();
    } catch (_) {
      _hydrateMovementsFromItem();
    } finally {
      isLoading.value = false;
    }
  }

  List<StockMovementModel> get filteredMovements {
    final filter = selectedFilter.value;
    final year = yearFilter.value;
    final month = monthFilter.value;
    return movements.where((movement) {
      if (!_matchesDate(movement, year, month)) return false;
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

  List<InventoryCostHistoryEntry> get filteredCostHistory {
    final year = yearFilter.value;
    final month = monthFilter.value;
    final list =
        costHistory
            .where((entry) => _matchesDateTime(entry.at, year, month))
            .toList();
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  void changeFilter(InventoryHistoryFilter filter) {
    if (selectedFilter.value == filter) return;
    selectedFilter.value = filter;
  }

  void setYearFilter(int year) {
    if (yearFilter.value == year) return;
    yearFilter.value = year;
    final months = monthsForYear(year);
    if (monthFilter.value != null && !months.contains(monthFilter.value)) {
      monthFilter.value = null;
    }
  }

  void setMonthFilter(int? month) {
    monthFilter.value = month;
  }

  List<int> get availableYears {
    final years = <int>{};
    final movementSource =
        movements.isNotEmpty
            ? movements
            : (item.value?.movements ?? const <StockMovementModel>[]);
    for (final movement in movementSource) {
      years.add(movement.createdAt.toLocal().year);
    }
    final costSource =
        costHistory.isNotEmpty
            ? costHistory
            : (item.value?.costHistory ?? const <InventoryCostHistoryEntry>[]);
    for (final entry in costSource) {
      years.add(entry.at.toLocal().year);
    }
    if (years.isEmpty) {
      years.add(DateTime.now().year);
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<int> monthsForYear(int year) {
    final months = <int>{};
    final movementSource =
        movements.isNotEmpty
            ? movements
            : (item.value?.movements ?? const <StockMovementModel>[]);
    for (final movement in movementSource) {
      final date = movement.createdAt.toLocal();
      if (date.year == year) {
        months.add(date.month);
      }
    }
    final costSource =
        costHistory.isNotEmpty
            ? costHistory
            : (item.value?.costHistory ?? const <InventoryCostHistoryEntry>[]);
    for (final entry in costSource) {
      final date = entry.at.toLocal();
      if (date.year == year) {
        months.add(date.month);
      }
    }
    if (months.isEmpty) {
      return List.generate(12, (index) => index + 1);
    }
    final list = months.toList()..sort();
    return list;
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
      costHistory.clear();
      return;
    }
    movements.assignAll(_sortMovements(source.movements));
    costHistory.assignAll(_sortCostHistory(source.costHistory));
    _syncFiltersWithData();
  }

  List<StockMovementModel> _sortMovements(List<StockMovementModel> source) {
    final list = List<StockMovementModel>.from(source);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<InventoryCostHistoryEntry> _sortCostHistory(
    List<InventoryCostHistoryEntry> source,
  ) {
    final list = List<InventoryCostHistoryEntry>.from(source);
    list.sort((a, b) => b.at.compareTo(a.at));
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

  bool _matchesDate(StockMovementModel movement, int year, int? month) =>
      _matchesDateTime(movement.createdAt, year, month);

  bool _matchesDateTime(DateTime date, int year, int? month) {
    final local = date.toLocal();
    if (local.year != year) return false;
    if (month != null && local.month != month) return false;
    return true;
  }

  Future<void> _loadCostHistory(InventoryItemModel freshItem) async {
    try {
      final fetched = await _inventoryService.getCostHistory(_itemId);
      if (fetched.isNotEmpty) {
        costHistory.assignAll(_sortCostHistory(fetched));
        return;
      }
    } catch (_) {
      // fall back to embedded history
    }
    costHistory.assignAll(_sortCostHistory(freshItem.costHistory));
  }

  void _syncFiltersWithData() {
    final years = availableYears;
    if (!years.contains(yearFilter.value)) {
      yearFilter.value = years.first;
    }
    final months = monthsForYear(yearFilter.value);
    if (monthFilter.value != null && !months.contains(monthFilter.value)) {
      monthFilter.value = null;
    }
  }
}
