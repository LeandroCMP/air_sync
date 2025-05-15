
import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/inventory_item_history/inventory_item_history_bindings.dart';
import 'package:air_sync/modules/inventory_item_history/inventory_item_history_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class InventoryItemHistoryModule implements Module{
  @override
  List<GetPage> routers = [
    GetPage(name: '/inventory/item', page: () => InventoryItemHistoryPage(), binding: InventoryItemHistoryBindings(),),
  ];
  
}