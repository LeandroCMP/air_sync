import '../../../../core/storage/local_database.dart';
import '../models/client_model.dart';

class ClientsLocalDataSource {
  ClientsLocalDataSource(this._database);

  final LocalDatabase _database;

  Future<List<ClientModel>> fetchAll() async {
    final rows = await _database.getAll('clients');
    return rows.map(ClientModel.fromDatabase).toList();
  }

  Future<void> upsert(ClientModel client) async {
    await _database.upsert('clients', client.id, client.toDatabase(), updatedAt: client.updatedAt?.toIso8601String());
  }

  Future<ClientModel?> getById(String id) async {
    final row = await _database.getById('clients', id);
    if (row == null) return null;
    return ClientModel.fromDatabase(row);
  }

  Future<void> delete(String id) => _database.delete('clients', id);
}
