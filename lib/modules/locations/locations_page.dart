import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'locations_controller.dart';

class LocationsPage extends GetView<LocationsController> {
  const LocationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Endereços', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LinearProgressIndicator(minHeight: 2);
        if (controller.items.isEmpty) {
          return const Center(child: Text('Sem endereços', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final l = controller.items[i];
            final addr = [l.street, l.number, l.city, l.state, l.zip].where((e) => (e ?? '').isNotEmpty).join(', ');
            return ListTile(
              title: Text(l.label, style: const TextStyle(color: Colors.white)),
              subtitle: Text(addr, style: const TextStyle(color: Colors.white70)),
            );
          },
        );
      }),
    );
  }
}

