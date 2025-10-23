import '../../../../core/storage/local_database.dart';
import '../models/inventory_item_model.dart';

class InventoryLocalDataSource {
  InventoryLocalDataSource(this._database);

  final LocalDatabase _database;

  Future<List<InventoryItemModel>> fetchAll() async {
    final rows = await _database.getAll('inventory_items');
    return rows.map(InventoryItemModel.fromDatabase).toList();
  }

  Future<void> upsert(InventoryItemModel item) async {
    await _database.upsert('inventory_items', item.id, item.toDatabase(), updatedAt: item.updatedAt?.toIso8601String());
  }

  Future<InventoryItemModel?> getById(String id) async {
    final row = await _database.getById('inventory_items', id);
    if (row == null) return null;
    return InventoryItemModel.fromDatabase(row);
  }
}
