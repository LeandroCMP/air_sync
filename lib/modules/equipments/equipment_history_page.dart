import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'equipment_history_controller.dart';
import 'widgets/maintenance_history_card.dart';

class EquipmentHistoryPage extends GetView<EquipmentHistoryController> {
  const EquipmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Histórico de manutenção',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Relatório (PDF)',
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
            onPressed: controller.exportPdf,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (controller.items.isEmpty) {
          return const Center(
            child: Text(
              'Sem registros',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder:
              (_, index) =>
                  MaintenanceHistoryCard(entry: controller.items[index]),
        );
      }),
    );
  }
}
