import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/contracts/contracts_bindings.dart';
import 'package:air_sync/modules/contracts/contracts_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class ContractsModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(name: '/contracts', page: () => const ContractsPage(), binding: ContractsBindings()),
  ];
}


