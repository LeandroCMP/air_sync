import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';

class InventoryServiceImpl implements InventoryService {
  final InventoryRepository _inventoryRepository;

  InventoryServiceImpl({required InventoryRepository inventoryRepository})
    : _inventoryRepository = inventoryRepository;

  @override
  Future<InventoryItemModel> registerItem(InventoryItemModel item) =>
      _inventoryRepository.registerItem(item);

  @override
  Future<void> updateItem(InventoryItemModel item) =>
      _inventoryRepository.updateItem(item);

  @override
  Future<List<InventoryItemModel>> getItems(String userId) =>
      _inventoryRepository.getItems(userId);

  @override
  Future<void> addRecord({
    required String itemId,
    required double quantityToAdd,
  }) => _inventoryRepository.addRecord(
    itemId: itemId,
    quantityToAdd: quantityToAdd,
  );
}
