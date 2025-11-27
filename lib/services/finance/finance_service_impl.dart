import 'package:air_sync/models/finance_anomaly_model.dart';
import 'package:air_sync/models/finance_audit_model.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/models/finance_forecast_model.dart';
import 'package:air_sync/models/finance_transaction.dart';
import 'package:air_sync/models/finance_reconciliation_model.dart';
import 'package:air_sync/repositories/finance/finance_repository.dart';
import 'package:air_sync/services/finance/finance_service.dart';

class FinanceServiceImpl implements FinanceService {
  final FinanceRepository _repo;
  FinanceServiceImpl({required FinanceRepository repo}) : _repo = repo;

  @override
  Future<List<FinanceTransactionModel>> list({
    required String type,
    String? status,
    DateTime? from,
    DateTime? to,
  }) =>
      _repo.list(type: type, status: status, from: from, to: to);

  @override
  Future<FinanceDashboardModel> dashboard({
    String? month,
    String? costCenterId,
  }) =>
      _repo.dashboard(month: month, costCenterId: costCenterId);

  @override
  Future<FinanceAuditModel> audit({String? costCenterId}) =>
      _repo.audit(costCenterId: costCenterId);

  @override
  Future<FinanceForecastModel> forecast({
    int days = 30,
    String? costCenterId,
  }) =>
      _repo.forecast(days: days, costCenterId: costCenterId);

  @override
  Future<void> pay({
    required String id,
    required String method,
    required double amount,
  }) =>
      _repo.pay(id: id, method: method, amount: amount);

  @override
  Future<void> allocateIndirectCosts({
    required DateTime from,
    required DateTime to,
    List<String> categories = const [],
  }) => _repo.allocateIndirectCosts(
    from: from,
    to: to,
    categories: categories,
  );

  @override
  Future<List<FinanceReconciliationPayment>> reconciliationPayments({
    String scope = 'all',
  }) => _repo.reconciliationPayments(scope: scope);

  @override
  Future<List<FinanceReconciliationIssue>> reconciliationReport({
    String scope = 'all',
  }) => _repo.reconciliationReport(scope: scope);

  @override
  Future<FinanceAnomalyReport> anomalies({
    required String month,
    String? costCenterId,
  }) => _repo.anomalies(month: month, costCenterId: costCenterId);
}
