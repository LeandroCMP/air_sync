import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../core/auth/session_manager.dart';
import 'routes.dart';
import 'theme/theme.dart';
import 'translations/app_translations.dart';

class AirSyncApp extends StatelessWidget {
  const AirSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AirSync',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: _initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child ?? const SizedBox.shrink(),
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 800, name: TABLET),
            Breakpoint(start: 801, end: 1920, name: DESKTOP),
            Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        );
      },
    );
  }

  String get _initialRoute {
    final sessionManager = Get.find<SessionManager>();
    return sessionManager.isLogged ? AppRoutes.home : AppRoutes.login;
  }
}
