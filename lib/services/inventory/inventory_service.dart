import 'package:air_sync/models/inventory_model.dart';

abstract class InventoryService {
  Future<InventoryItemModel> registerItem({
    required String name,
    required String sku,
    required double minQty,
    String? barcode,
    String? unit, // 'un' | 'lt' | 'kg'
    double? maxQty,
    String? supplierId,
    double? avgCost,
    double? sellPrice,
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
}
