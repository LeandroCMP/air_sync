import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/storage/local_database.dart';
import 'app.dart';
import 'di.dart';

Future<void> bootstrap() async {
  await _loadEnvironments();
  await GetStorage.init();

  final database = LocalDatabase();
  await database.init();

  await DependencyConfig().init(database: database);

  runZonedGuarded(
    () => runApp(const AirSyncApp()),
    (error, stackTrace) => Get.log('Uncaught exception: $error\n$stackTrace'),
  );
}

Future<void> _loadEnvironments() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }
}
