import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_bindings.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_page.dart';
import 'package:get/get.dart';

class SubscriptionsModule implements Module {
  @override
  List<GetPage<dynamic>> routers = [
    GetPage(
      name: '/subscriptions',
      binding: SubscriptionsBindings(),
      page: () => const SubscriptionsPage(),
    ),
  ];
}
