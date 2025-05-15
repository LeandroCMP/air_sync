
import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/client_details/client_details_bindings.dart';
import 'package:air_sync/modules/client_details/client_details_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class ClientDetailsModule implements Module{
  @override
  List<GetPage> routers = [
    GetPage(name: '/client/details', page: () => ClientDetailsPage(), binding: ClientDetailsBindings(),),
  ];
  
}