import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/profile/user_profile_bindings.dart';
import 'package:air_sync/modules/profile/user_profile_page.dart';
import 'package:get/get.dart';

class UserProfileModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(
      name: '/profile',
      page: () => const UserProfilePage(),
      binding: UserProfileBindings(),
    ),
  ];
}
