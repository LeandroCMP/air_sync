import 'package:air_sync/models/inventory_model.dart';

abstract class InventoryRepository {
  Future<InventoryItemModel> registerItem(InventoryItemModel item);
  Future<List<InventoryItemModel>> getItems(String userId);
  Future<void> updateItem(InventoryItemModel item);
  Future<void> addRecord({required String itemId, required double quantityToAdd});
}
