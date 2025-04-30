import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Hero(tag: 'logo', child: FlutterLogo(size: 150))),
    );
  }
}
