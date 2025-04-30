import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  Future<void> onReady() async {
    await Future.delayed(1.seconds, () async {});
    Get.offAndToNamed('/login');
    super.onReady();
  }
}
