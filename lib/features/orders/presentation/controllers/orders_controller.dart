import 'package:get/get.dart';

import '../../domain/entities/order.dart';
import '../../domain/usecases/get_orders_usecase.dart';

class OrdersController extends GetxController {
  OrdersController(this._getOrdersUseCase);

  final GetOrdersUseCase _getOrdersUseCase;

  final orders = <ServiceOrder>[].obs;
  final isLoading = false.obs;
  final filters = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final result = await _getOrdersUseCase.call(filters: filters);
    isLoading.value = false;
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (data) => orders.assignAll(data),
    );
  }

  void updateFilter(String key, dynamic value) {
    filters[key] = value;
    load();
  }
}
