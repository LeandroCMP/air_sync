
import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/air_conditioner/air_conditioner_bindings.dart';
import 'package:air_sync/modules/air_conditioner/air_conditioner_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class AirConditionerModule implements Module{
  @override
  List<GetPage> routers = [
    GetPage(name: '/client/details/airconditioner', page: () => AirConditionerPage(), binding: AirConditionerBindings(),),
  ];
  
}