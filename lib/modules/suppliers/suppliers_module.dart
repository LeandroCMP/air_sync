import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/suppliers/suppliers_bindings.dart';
import 'package:air_sync/modules/suppliers/suppliers_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class SuppliersModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(name: '/suppliers', page: () => const SuppliersPage(), binding: SuppliersBindings()),
  ];
}


