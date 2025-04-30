import 'package:get/get.dart';
import 'package:flutter/material.dart';
import './client_controller.dart';

class ClientPage extends GetView<ClientController> {
    
    const ClientPage({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('ClientPage'),),
            body: Container(),
        );
    }
}