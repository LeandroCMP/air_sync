import 'package:air_sync/models/finance_audit_model.dart';
import 'package:air_sync/models/finance_anomaly_model.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/models/finance_forecast_model.dart';
import 'package:air_sync/models/finance_transaction.dart';

abstract class FinanceService {
  Future<List<FinanceTransactionModel>> list({
    required String type,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  });

  Future<FinanceDashboardModel> dashboard({
    String? month,
  });

  Future<FinanceAuditModel> audit();

  Future<FinanceForecastModel> forecast({
    int days = 30,
  });

  Future<void> pay({
    required String id,
    required String method,
    double? amount,
    String? idempotencyKey,
  });

  Future<void> allocateIndirectCosts({
    required DateTime from,
    required DateTime to,
    List<String> categories,
  });

  Future<FinanceAnomalyReport> anomalies({
    required String month,
  });
}
