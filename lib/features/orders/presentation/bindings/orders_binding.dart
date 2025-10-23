import 'package:get/get.dart';

import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/deduct_materials_usecase.dart';
import '../../domain/usecases/finish_order_usecase.dart';
import '../../domain/usecases/get_order_detail_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/reserve_materials_usecase.dart';
import '../../domain/usecases/start_order_usecase.dart';
import '../../domain/usecases/update_order_usecase.dart';
import '../controllers/order_detail_controller.dart';
import '../controllers/orders_controller.dart';

class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrdersController>(() => OrdersController(Get.find<GetOrdersUseCase>()));
    Get.lazyPut<OrderDetailController>(() => OrderDetailController(
          Get.find<GetOrderDetailUseCase>(),
          Get.find<CreateOrderUseCase>(),
          Get.find<UpdateOrderUseCase>(),
          Get.find<StartOrderUseCase>(),
          Get.find<FinishOrderUseCase>(),
          Get.find<ReserveMaterialsUseCase>(),
          Get.find<DeductMaterialsUseCase>(),
        ));
  }
}
