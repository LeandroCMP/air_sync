import 'package:air_sync/application/bindings/application_bindings.dart';
import 'package:air_sync/application/ui/airSync_app_ui_config.dart';
import 'package:air_sync/modules/air_conditioner/air_conditioner_module.dart';
import 'package:air_sync/modules/client/client_module.dart';
import 'package:air_sync/modules/client_details/client_details_module.dart';
import 'package:air_sync/modules/home/home_module.dart';
import 'package:air_sync/modules/inventory/inventory_module.dart';
import 'package:air_sync/modules/inventory_item_history/inventory_item_history_module.dart';
import 'package:air_sync/modules/suppliers/suppliers_module.dart';
import 'package:air_sync/modules/purchases/purchases_module.dart';
import 'package:air_sync/modules/contracts/contracts_module.dart';
import 'package:air_sync/modules/fleet/fleet_module.dart';
import 'package:air_sync/modules/timeline/timeline_module.dart';
import 'package:air_sync/modules/users/users_module.dart';
import 'package:air_sync/modules/login/login_module.dart';
import 'package:air_sync/modules/splash/splash_module.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa formatação pt_BR (datas e moedas)
  try {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  } catch (_) {
    // se falhar, segue com locale padrão
  }
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
        ...SuppliersModule().routers,
        ...PurchasesModule().routers,
        ...ContractsModule().routers,
        ...FleetModule().routers,
        ...TimelineModule().routers,
        ...UsersModule().routers,
      ],
    );
  }
}
