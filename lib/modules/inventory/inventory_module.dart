
import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/inventory/inventory_bindings.dart';
import 'package:air_sync/modules/inventory/inventory_page.dart';
import 'package:air_sync/modules/inventory/inventory_rebalance_bindings.dart';
import 'package:air_sync/modules/inventory/inventory_rebalance_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class InventoryModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(
      name: '/inventory',
      page: () => const InventoryPage(),
      binding: InventoryBindings(),
    ),
    GetPage(
      name: '/inventory/rebalance',
      page: () => const InventoryRebalancePage(),
      binding: InventoryRebalanceBindings(),
    ),
  ];
}
