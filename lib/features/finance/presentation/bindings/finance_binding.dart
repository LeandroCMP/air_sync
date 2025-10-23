import 'package:get/get.dart';

import '../../domain/usecases/get_dre_usecase.dart';
import '../../domain/usecases/get_finance_kpis_usecase.dart';
import '../../domain/usecases/get_finance_transactions_usecase.dart';
import '../../domain/usecases/pay_transaction_usecase.dart';
import '../controllers/finance_controller.dart';

class FinanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinanceController>(() => FinanceController(
          Get.find<GetFinanceTransactionsUseCase>(),
          Get.find<PayTransactionUseCase>(),
          Get.find<GetDreUseCase>(),
          Get.find<GetFinanceKpisUseCase>(),
        ));
  }
}
