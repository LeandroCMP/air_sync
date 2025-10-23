import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes.dart';
import '../../../../app/widgets/empty_state.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../app/widgets/status_tag.dart';
import '../../../../app/utils/formatters.dart';
import '../controllers/client_list_controller.dart';

class ClientListPage extends GetView<ClientListController> {
  const ClientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.load,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed(AppRoutes.clientDetail, parameters: {'mode': 'create'}),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar clientes...'),
              onChanged: (value) {
                controller.filter.value = value;
                controller.load();
              },
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.clients.isEmpty) {
          return EmptyState(
            title: 'Cadastre seu primeiro cliente',
            subtitle: 'Clientes sincronizados também aparecem aqui quando offline.',
            actionLabel: 'Novo cliente',
            onAction: () => Get.toNamed(AppRoutes.clientDetail, parameters: {'mode': 'create'}),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.clients.length,
          itemBuilder: (context, index) {
            final client = controller.clients[index];
            return SectionCard(
              title: client.name,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Get.toNamed(AppRoutes.clientDetail, parameters: {'id': client.id}),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.remove(client.id),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client.document != null) StatusTag(label: Formatters.cpfCnpj(client.document!)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      for (final phone in client.phones) Chip(label: Text(phone)),
                      for (final email in client.emails) Chip(label: Text(email)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
