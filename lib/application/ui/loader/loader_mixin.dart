import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

mixin LoaderMixin on GetxController {
  void loaderListener(RxBool loaderRx) {
    ever(loaderRx, (loading) async {
      if (loading) {
        await Get.dialog(
          Center(
            child: LoadingAnimationWidget.threeArchedCircle(
              color: Colors.white,
              size: 50,
            ),
          ),
          barrierDismissible: false,
        );
      } else {
        Get.back();
      }
    });
  }
}
