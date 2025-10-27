import 'package:air_sync/models/finance_transaction.dart';
import 'package:air_sync/repositories/finance/finance_repository.dart';
import 'package:air_sync/services/finance/finance_service.dart';

class FinanceServiceImpl implements FinanceService {
  final FinanceRepository _repo;
  FinanceServiceImpl({required FinanceRepository repo}) : _repo = repo;

  @override
  Future<List<FinanceTransactionModel>> list({required String type, String? status, DateTime? from, DateTime? to}) =>
      _repo.list(type: type, status: status, from: from, to: to);

  @override
  Future<void> pay({required String id, required String method, required double amount}) =>
      _repo.pay(id: id, method: method, amount: amount);
}

