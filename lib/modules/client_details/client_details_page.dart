import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './client_details_controller.dart';

class ClientDetailsPage extends GetView<ClientDetailsController> {
  const ClientDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Cliente', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        child: const Icon(Icons.phone, color: Colors.white),
        onPressed: () => controller.launchDialer(controller.client.value.primaryPhone),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Obx(() {
          final c = controller.client.value;
          return ListTile(
            contentPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: context.themeGray,
            leading: CircleAvatar(
              backgroundColor: context.themeLightGray,
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
            title: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
            subtitle: Text(c.primaryPhone, style: const TextStyle(color: Colors.white70)),
          );
        }),
      ),
    );
  }
}

