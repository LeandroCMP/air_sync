import 'package:air_sync/application/modules/module.dart';
import 'package:get/get.dart';

import 'users_bindings.dart';
import 'users_page.dart';

class UsersModule extends Module {
  @override
  List<GetPage> routers = [
    GetPage(
      name: '/users',
      page: () => const UsersPage(),
      binding: UsersBindings(),
    ),
  ];
}
