import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes.dart';
import '../../../../app/widgets/empty_state.dart';
import '../../../../app/widgets/stat_tile.dart';
import '../../domain/entities/inventory_item.dart';
import '../controllers/inventory_controller.dart';

class InventoryPage extends GetView<InventoryController> {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: controller.load)],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.items.isEmpty) {
          return const EmptyState(title: 'Nenhum item cadastrado', subtitle: 'Cadastre itens via dashboard web.');
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: controller.lowStockItems
                      .map(
                        (item) => SizedBox(
                          width: 220,
                          child: StatTile(
                            title: item.name,
                            value: 'Saldo: ${item.onHand}',
                            trend: item.isLowStock ? 'Estoque crítico' : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              ...controller.items.map((item) => _InventoryCard(item: item)).toList(),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() => controller.items.isEmpty
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: () => Get.toNamed(AppRoutes.inventoryItem, parameters: {'id': controller.items.first.id}),
              child: const Icon(Icons.qr_code_scanner),
            )),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('SKU ${item.sku} • Em estoque: ${item.onHand}'),
        trailing: Icon(item.isLowStock ? Icons.warning_amber : Icons.check_circle, color: item.isLowStock ? Colors.amber : Colors.green),
        onTap: () => Get.toNamed(AppRoutes.inventoryItem, parameters: {'id': item.id}),
      ),
    );
  }
}
