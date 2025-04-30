import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/home/home_bindings.dart';
import 'package:air_sync/modules/home/home_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class HomeModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(name: '/home', page: () => HomePage(), binding: HomeBindings()),
  ];
}
