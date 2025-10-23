import '../../../../core/storage/local_database.dart';
import '../models/finance_transaction_model.dart';

class FinanceLocalDataSource {
  FinanceLocalDataSource(this._database);

  final LocalDatabase _database;

  Future<List<FinanceTransactionModel>> fetchAll() async {
    final rows = await _database.getAll('finance_transactions');
    return rows.map(FinanceTransactionModel.fromDatabase).toList();
  }

  Future<void> upsert(FinanceTransactionModel model) async {
    await _database.upsert('finance_transactions', model.id, model.toDatabase(), updatedAt: model.dueDate?.toIso8601String());
  }
}
