import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/cost_centers/cost_centers_bindings.dart';
import 'package:air_sync/modules/cost_centers/cost_centers_page.dart';
import 'package:get/get.dart';

class CostCentersModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(
      name: '/finance/cost-centers',
      page: () => const CostCentersPage(),
      binding: CostCentersBindings(),
    ),
  ];
}
