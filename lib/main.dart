import 'package:air_sync/application/bindings/application_bindings.dart';
import 'package:air_sync/application/ui/airSync_app_ui_config.dart';
import 'package:air_sync/modules/air_conditioner/air_conditioner_module.dart';
import 'package:air_sync/modules/client/client_module.dart';
import 'package:air_sync/modules/client_details/client_details_module.dart';
import 'package:air_sync/modules/home/home_module.dart';
import 'package:air_sync/modules/inventory/inventory_module.dart';
import 'package:air_sync/modules/inventory_item_history/inventory_item_history_module.dart';
import 'package:air_sync/modules/login/login_module.dart';
import 'package:air_sync/modules/splash/splash_module.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AirSyncAppUiConfig.tittle,
      theme: AirSyncAppUiConfig.theme,
      initialBinding: ApplicationBindings(),
      getPages: [
        ...SplashModule().routers,
        ...LoginModule().routers,
        ...HomeModule().routers,
        ...ClientModule().routers,
        ...ClientDetailsModule().routers,
        ...AirConditionerModule().routers,
        ...InventoryModule().routers,
        ...InventoryItemHistoryModule().routers,
      ],
    );
  }
}
