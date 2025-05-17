import 'package:air_sync/models/inventory_model.dart';

abstract class InventoryRepository {
  Future<InventoryItemModel> registerItem(InventoryItemModel item);
  Future<List<InventoryItemModel>> getItems(String userId);
  Future<void> updateItem(InventoryItemModel item);
  Future<void> deleteItem(String itemId);
  Future<void> addRecord({required String itemId,required double quantityToAdd});
  Future<void> deleteEntry({required String itemId, required String entryId});
}
