import 'package:air_sync/models/finance_reconciliation_model.dart';
import 'package:air_sync/services/finance/finance_service.dart';
import 'package:get/get.dart';

class FinanceReconciliationController extends GetxController {
  FinanceReconciliationController({FinanceService? service})
      : _service = service ?? Get.find<FinanceService>();

  final FinanceService _service;
  final RxString scope = 'all'.obs;
  final RxBool loading = false.obs;
  final RxList<FinanceReconciliationPayment> payments =
      <FinanceReconciliationPayment>[].obs;
  final RxList<FinanceReconciliationIssue> issues =
      <FinanceReconciliationIssue>[].obs;
  final RxString error = ''.obs;

  final List<String> scopes = const ['all', 'orders', 'purchases'];

  @override
  Future<void> onReady() async {
    await load();
    super.onReady();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      final currentScope = scope.value;
      final results = await Future.wait([
        _service.reconciliationPayments(scope: currentScope),
        _service.reconciliationReport(scope: currentScope),
      ]);
      payments.assignAll(results[0] as List<FinanceReconciliationPayment>);
      issues.assignAll(results[1] as List<FinanceReconciliationIssue>);
    } catch (_) {
      error.value =
          'Falha ao carregar os dados de reconciliação. Tente novamente.';
      payments.clear();
      issues.clear();
    } finally {
      loading.value = false;
    }
  }

  void setScope(String value) {
    if (scope.value == value) return;
    scope.value = value;
    load();
  }
}
