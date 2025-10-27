import 'package:air_sync/models/finance_transaction.dart';

abstract class FinanceService {
  Future<List<FinanceTransactionModel>> list({required String type, String? status, DateTime? from, DateTime? to});
  Future<void> pay({required String id, required String method, required double amount});
}

