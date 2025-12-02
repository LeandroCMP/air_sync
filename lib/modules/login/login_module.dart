import 'package:air_sync/application/modules/module.dart';
import 'package:air_sync/modules/login/forgot_password_bindings.dart';
import 'package:air_sync/modules/login/forgot_password_page.dart';
import 'package:air_sync/modules/login/login_bindings.dart';
import 'package:air_sync/modules/login/login_page.dart';
import 'package:air_sync/modules/login/reset_password_bindings.dart';
import 'package:air_sync/modules/login/reset_password_page.dart';
import 'package:air_sync/modules/login/change_temp_password_bindings.dart';
import 'package:air_sync/modules/login/change_temp_password_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class LoginModule implements Module {
  @override
  List<GetPage> routers = [
    GetPage(name: '/login', page: () => LoginPage(), binding: LoginBindings()),
    GetPage(
      name: '/forgot-password',
      page: () => const ForgotPasswordPage(),
      binding: ForgotPasswordBindings(),
    ),
    GetPage(
      name: '/reset-password',
      page: () => const ResetPasswordPage(),
      binding: ResetPasswordBindings(),
    ),
    GetPage(
      name: '/change-temp-password',
      page: () => const ChangeTempPasswordPage(),
      binding: ChangeTempPasswordBindings(),
    ),
  ];
}
