import '../../../../core/storage/local_database.dart';
import '../models/order_model.dart';

class OrdersLocalDataSource {
  OrdersLocalDataSource(this._database);

  final LocalDatabase _database;

  Future<List<OrderModel>> fetchAll() async {
    final rows = await _database.getAll('orders');
    return rows.map(OrderModel.fromDatabase).toList();
  }

  Future<void> upsert(OrderModel order) async {
    await _database.upsert('orders', order.id, order.toDatabase(), updatedAt: order.updatedAt?.toIso8601String());
  }

  Future<OrderModel?> getById(String id) async {
    final row = await _database.getById('orders', id);
    if (row == null) return null;
    return OrderModel.fromDatabase(row);
  }
}
