import 'package:air_sync/application/bindings/application_bindings.dart';
import 'package:air_sync/application/core/network/app_config.dart';
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
import 'package:air_sync/modules/cost_centers/cost_centers_module.dart';
import 'package:air_sync/modules/sales/sales_module.dart';
import 'package:air_sync/modules/profile/user_profile_module.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
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
  final appConfig = AppConfig();
  await appConfig.load();
  if (appConfig.stripePublishableKey.isNotEmpty) {
    stripe.Stripe.publishableKey = appConfig.stripePublishableKey;
    stripe.Stripe.merchantIdentifier = 'merchant.com.airsync';
    await stripe.Stripe.instance.applySettings();
  }
  runApp(MyApp(appConfig: appConfig));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appConfig});

  final AppConfig appConfig;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AirSyncAppUiConfig.tittle,
      theme: AirSyncAppUiConfig.theme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialBinding: ApplicationBindings(appConfig: appConfig),
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
        ...CostCentersModule().routers,
        ...SalesModule().routers,
        ...SubscriptionsModule().routers,
        ...UserProfileModule().routers,
        ...UsersModule().routers,
      ],
    );
  }
}
