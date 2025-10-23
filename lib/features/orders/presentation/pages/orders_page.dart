import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../app/widgets/empty_state.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../app/widgets/status_tag.dart';
import '../controllers/orders_controller.dart';

class OrdersPage extends GetView<OrdersController> {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.load),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.orders.isEmpty) {
          return EmptyState(
            title: 'Nenhuma OS',
            subtitle: 'Crie uma OS para começar a atender seus clientes.',
            actionLabel: 'Nova OS',
            onAction: () => Get.toNamed(AppRoutes.orderDetail, parameters: {'mode': 'create'}),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            return SectionCard(
              title: order.clientName,
              actions: [
                StatusTag(label: order.status),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => Get.toNamed(AppRoutes.orderDetail, parameters: {'id': order.id}),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.scheduledAt != null)
                    Text('Agendada para: ${Formatters.dateTime(order.scheduledAt!)}'),
                  if (order.equipment != null)
                    Text('Equipamento: ${order.equipment}'),
                  if (order.totalMinutes != null)
                    Text('Tempo total: ${order.totalMinutes} min'),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.orderDetail, parameters: {'mode': 'create'}),
        icon: const Icon(Icons.add),
        label: const Text('Nova OS'),
      ),
    );
  }
}
