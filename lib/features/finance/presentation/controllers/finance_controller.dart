import 'package:get/get.dart';

import '../../../../app/utils/formatters.dart';
import '../../domain/entities/dre_report.dart';
import '../../domain/entities/finance_transaction.dart';
import '../../domain/entities/kpi_report.dart';
import '../../domain/usecases/get_dre_usecase.dart';
import '../../domain/usecases/get_finance_kpis_usecase.dart';
import '../../domain/usecases/get_finance_transactions_usecase.dart';
import '../../domain/usecases/pay_transaction_usecase.dart';

class FinanceController extends GetxController {
  FinanceController(this._getTransactions, this._payTransaction, this._getDre, this._getKpis);

  final GetFinanceTransactionsUseCase _getTransactions;
  final PayTransactionUseCase _payTransaction;
  final GetDreUseCase _getDre;
  final GetFinanceKpisUseCase _getKpis;

  final receivables = <FinanceTransaction>[].obs;
  final payables = <FinanceTransaction>[].obs;
  final dre = Rxn<DreReport>();
  final kpis = <FinanceKpiReport>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final receivablesResult = await _getTransactions.call(type: 'receivable');
    final payablesResult = await _getTransactions.call(type: 'payable');
    final dreResult = await _getDre.call();
    final kpiResult = await _getKpis.call();
    isLoading.value = false;

    receivablesResult.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => receivables.assignAll(data),
    );
    payablesResult.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => payables.assignAll(data),
    );
    dreResult.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => dre.value = data,
    );
    kpiResult.fold(
      (failure) => Get.log('Erro KPI: ${failure.message}'),
      (data) => kpis.assignAll(data),
    );
  }

  Future<void> pay(String id, double amount, String method) async {
    final result = await _payTransaction.call(id, {'amount': amount, 'method': method});
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) {
        Get.snackbar('Sucesso', 'Pagamento registrado (${Formatters.money(amount)})');
        load();
      },
    );
  }
}
