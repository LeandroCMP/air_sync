import 'package:air_sync/models/finance_anomaly_model.dart';
import 'package:air_sync/models/finance_audit_model.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/models/finance_forecast_model.dart';
import 'package:air_sync/models/finance_transaction.dart';
import 'package:air_sync/repositories/finance/finance_repository.dart';
import 'package:air_sync/services/finance/finance_service.dart';
import 'package:uuid/uuid.dart';

class FinanceServiceImpl implements FinanceService {
  final FinanceRepository _repo;
  FinanceServiceImpl({required FinanceRepository repo}) : _repo = repo;

  @override
  Future<List<FinanceTransactionModel>> list({
    required String type,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) =>
      _repo.list(
        type: type,
        status: status,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );

  @override
  Future<FinanceDashboardModel> dashboard({
    String? month,
  }) =>
      _repo.dashboard(month: month);

  @override
  Future<FinanceAuditModel> audit() => _repo.audit();

  @override
  Future<FinanceForecastModel> forecast({
    int days = 30,
  }) =>
      _repo.forecast(days: days);

  @override
  Future<void> pay({
    required String id,
    required String method,
    double? amount,
    String? idempotencyKey,
  }) {
    final key = idempotencyKey ?? const Uuid().v4();
    return _repo.pay(
      id: id,
      method: method,
      amount: amount,
      idempotencyKey: key,
    );
  }

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
  Future<FinanceAnomalyReport> anomalies({
    required String month,
  }) => _repo.anomalies(month: month);
}
