import 'package:air_sync/models/finance_anomaly_model.dart';
import 'package:air_sync/models/finance_audit_model.dart';
import 'package:air_sync/models/finance_dashboard_model.dart';
import 'package:air_sync/models/finance_forecast_model.dart';
import 'package:air_sync/models/finance_transaction.dart';
import 'package:air_sync/models/finance_reconciliation_model.dart';

abstract class FinanceRepository {
  Future<List<FinanceTransactionModel>> list({
    required String type, // receivable | payable
    String? status, // pending | paid
    DateTime? from,
    DateTime? to,
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
    required double amount,
  });

  Future<void> allocateIndirectCosts({
    required DateTime from,
    required DateTime to,
    List<String> categories,
  });

  Future<List<FinanceReconciliationPayment>> reconciliationPayments({
    String scope = 'all',
  });

  Future<List<FinanceReconciliationIssue>> reconciliationReport({
    String scope = 'all',
  });

  Future<FinanceAnomalyReport> anomalies({
    required String month,
  });
}
