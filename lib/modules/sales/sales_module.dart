import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/sales/sales_bindings.dart';
import 'package:air_sync/modules/sales/sales_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class SalesModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(
      name: '/sales',
      page: () => const SalesPage(),
      binding: SalesBindings(),
    ),
  ];
}
