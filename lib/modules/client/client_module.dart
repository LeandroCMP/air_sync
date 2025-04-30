
import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/client/client_bindings.dart';
import 'package:air_sync/modules/client/client_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class ClientModule implements Module{
  @override
  List<GetPage> routers = [
    GetPage(name: '/client', page: () => ClientPage(), binding: ClientBindings(),),
  ];
  
}