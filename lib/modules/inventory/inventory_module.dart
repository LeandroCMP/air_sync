
import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/inventory/inventory_bindings.dart';
import 'package:air_sync/modules/inventory/inventory_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class InventoryModule implements Module{
  @override
  List<GetPage> routers = [
    GetPage(name: '/inventory', page: () => InventoryPage(), binding: InventoryBindings(),),
  ];
  
}