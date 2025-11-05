import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/fleet/fleet_bindings.dart';
import 'package:air_sync/modules/fleet/fleet_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class FleetModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(name: '/fleet', page: () => const FleetPage(), binding: FleetBindings()),
  ];
}


