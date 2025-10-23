import 'package:flutter/material.dart';

import 'app/main.dart' as app_main;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app_main.bootstrap();
}
