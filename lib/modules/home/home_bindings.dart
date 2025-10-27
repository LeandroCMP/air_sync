import 'package:get/get.dart';
import './home_controller.dart';
import 'package:air_sync/modules/client/client_bindings.dart';
import 'package:air_sync/modules/inventory/inventory_bindings.dart';
import 'package:air_sync/modules/orders/orders_bindings.dart';

class HomeBindings implements Bindings {
  @override
  void dependencies() {
    // Prepara dependências para abas Clientes e Estoque
    ClientBindings().dependencies();
    InventoryBindings().dependencies();
    OrdersBindings().dependencies();
    Get.put(
      HomeController(
        authService: Get.find(),
        authServiceApplication: Get.find(),
      ),
    );
  }
}
