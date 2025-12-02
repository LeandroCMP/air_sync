import 'package:air_sync/models/inventory_category_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/inventory_rebalance_model.dart';

abstract class InventoryService {
  Future<InventoryItemModel> registerItem({
    required String name,
    String? sku,
    required double minQty,
    String? unit, // 'un' | 'lt' | 'kg'
    double? maxQty,
    String? supplierId,
    double? avgCost,
    double? sellPrice,
    String? categoryId,
    double? markupPercent,
    String? pricingMode,
  });
  Future<List<InventoryItemModel>> getItems({
    String? userId,
    String text = '',
    int? page,
    int? limit,
    bool? belowMin,
  });
  Future<void> updateItem(InventoryItemModel item);
  Future<void> deleteItem(String itemId);
  Future<void> addRecord({
    required String itemId,
    required double quantityToAdd,
  });
  Future<void> deleteEntry({required String itemId, required String entryId});

  // Spec-compliant operations
  Future<List<InventoryItemModel>> listItems({
    String? q,
    bool? active,
    bool? belowMin,
    int? page,
    int? limit,
  });
  Future<InventoryItemModel> getItem(String id);
  Future<void> patchItem(String id, Map<String, dynamic> changes);
  Future<List<InventoryCostHistoryEntry>> getCostHistory(String id);
  Future<List<StockLevelModel>> getStockLevels({
    String? itemId,
    String? locationId,
  });
  Future<StockMovementModel> createMovement({
    required String itemId,
    String? locationId,
    required double quantity,
    required MovementType type,
    String? reason,
    String? documentRef,
    String? idempotencyKey,
  });
  Future<void> transferStock({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required double quantity,
    String? reason,
    String? documentRef,
    String? idempotencyKey,
  });
  Future<List<StockMovementModel>> listMovements({
    required String itemId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<InventoryCategoryModel>> listCategories({String? search});
  Future<InventoryCategoryModel> createCategory({
    required String name,
    required double markupPercent,
    String? description,
  });
  Future<InventoryCategoryModel> updateCategory({
    required String id,
    String? name,
    double? markupPercent,
    String? description,
  });
  Future<void> deleteCategory(String id);

  Future<List<InventoryRebalanceSuggestion>> rebalance({int days = 30});

  Future<List<InventoryRebalanceSuggestion>> purchaseForecast({int days = 30});
}
