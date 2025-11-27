import 'package:air_sync/models/inventory_category_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/inventory_rebalance_model.dart';
import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';

class InventoryServiceImpl implements InventoryService {
  final InventoryRepository _inventoryRepository;

  InventoryServiceImpl({required InventoryRepository inventoryRepository})
    : _inventoryRepository = inventoryRepository;

  @override
  Future<InventoryItemModel> registerItem({
    required String name,
    required String sku,
    required double minQty,
    String? barcode,
    String? unit,
    double? maxQty,
    String? supplierId,
    double? avgCost,
    double? sellPrice,
    String? categoryId,
    double? markupPercent,
    String? pricingMode,
  }) => _inventoryRepository.registerItem(
    name: name,
    sku: sku,
    minQty: minQty,
    barcode: barcode,
    unit: unit,
    maxQty: maxQty,
    supplierId: supplierId,
    avgCost: avgCost,
    sellPrice: sellPrice,
    categoryId: categoryId,
    markupPercent: markupPercent,
    pricingMode: pricingMode,
  );

  @override
  Future<void> updateItem(InventoryItemModel item) =>
      _inventoryRepository.updateItem(item);

  @override
  Future<List<InventoryItemModel>> getItems({
    String? userId,
    String text = '',
    int? page,
    int? limit,
    bool? belowMin,
  }) => _inventoryRepository.getItems(
    userId: userId,
    text: text,
    page: page,
    limit: limit,
    belowMin: belowMin,
  );

  @override
  Future<void> addRecord({
    required String itemId,
    required double quantityToAdd,
  }) => _inventoryRepository.addRecord(
    itemId: itemId,
    quantityToAdd: quantityToAdd,
  );

  @override
  Future<void> deleteEntry({required String itemId, required String entryId}) =>
      _inventoryRepository.deleteEntry(itemId: itemId, entryId: entryId);

  @override
  Future<void> deleteItem(String itemId) =>
      _inventoryRepository.deleteItem(itemId);

  // Spec-compliant operations
  @override
  Future<List<InventoryItemModel>> listItems({
    String? q,
    bool? active,
    bool? belowMin,
    int? page,
    int? limit,
  }) => _inventoryRepository.listItems(
    q: q,
    active: active,
    belowMin: belowMin,
    page: page,
    limit: limit,
  );

  @override
  Future<InventoryItemModel> getItem(String id) =>
      _inventoryRepository.getItem(id);

  @override
  Future<void> patchItem(String id, Map<String, dynamic> changes) =>
      _inventoryRepository.patchItem(id, changes);

  @override
  Future<List<InventoryCostHistoryEntry>> getCostHistory(String id) =>
      _inventoryRepository.getCostHistory(id);

  @override
  Future<List<StockLevelModel>> getStockLevels({
    String? itemId,
    String? locationId,
  }) => _inventoryRepository.getStockLevels(
    itemId: itemId,
    locationId: locationId,
  );

  @override
  Future<StockMovementModel> createMovement({
    required String itemId,
    String? locationId,
    required double quantity,
    required MovementType type,
    String? reason,
    String? documentRef,
    String? idempotencyKey,
  }) => _inventoryRepository.createMovement(
    itemId: itemId,
    locationId: locationId,
    quantity: quantity,
    type: type,
    reason: reason,
    documentRef: documentRef,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<void> transferStock({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required double quantity,
    String? reason,
    String? documentRef,
    String? idempotencyKey,
  }) => _inventoryRepository.transferStock(
    itemId: itemId,
    fromLocationId: fromLocationId,
    toLocationId: toLocationId,
    quantity: quantity,
    reason: reason,
    documentRef: documentRef,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<List<StockMovementModel>> listMovements({
    required String itemId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) => _inventoryRepository.listMovements(
    itemId: itemId,
    limit: limit,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<List<InventoryCategoryModel>> listCategories({String? search}) =>
      _inventoryRepository.listCategories(search: search);

  @override
  Future<InventoryCategoryModel> createCategory({
    required String name,
    required double markupPercent,
    String? description,
  }) => _inventoryRepository.createCategory(
    name: name,
    markupPercent: markupPercent,
    description: description,
  );

  @override
  Future<InventoryCategoryModel> updateCategory({
    required String id,
    String? name,
    double? markupPercent,
    String? description,
  }) => _inventoryRepository.updateCategory(
    id: id,
    name: name,
    markupPercent: markupPercent,
    description: description,
  );

  @override
  Future<void> deleteCategory(String id) =>
      _inventoryRepository.deleteCategory(id);

  @override
  Future<List<InventoryRebalanceSuggestion>> rebalance({int days = 30}) =>
      _inventoryRepository.rebalance(days: days);

  @override
  Future<List<InventoryRebalanceSuggestion>> purchaseForecast({int days = 30}) =>
      _inventoryRepository.purchaseForecast(days: days);
}
