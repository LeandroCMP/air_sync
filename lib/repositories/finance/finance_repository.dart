import 'package:air_sync/models/finance_transaction.dart';

abstract class FinanceRepository {
  Future<List<FinanceTransactionModel>> list({
    required String type, // receivable | payable
    String? status, // pending | paid
    DateTime? from,
    DateTime? to,
  });

  Future<void> pay({required String id, required String method, required double amount});
}

