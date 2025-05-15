import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './air_conditioner_controller.dart';

class AirConditionerPage extends GetView<AirConditionerController> {
    
    const AirConditionerPage({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('AirConditionerPage'),),
            body: Container(),
        );
    }
}