import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes.dart';
import '../../../clients/presentation/pages/client_list_page.dart';
import '../../../finance/presentation/pages/finance_page.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import '../../../sync/presentation/controllers/sync_controller.dart';
import '../controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            OrdersPage(),
            ClientListPage(),
            InventoryPage(),
            FinancePage(),
            _SyncTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.currentIndex.value,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_today), label: 'OS'),
            NavigationDestination(icon: Icon(Icons.people_alt), label: 'Clientes'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Estoque'),
            NavigationDestination(icon: Icon(Icons.attach_money), label: 'Financeiro'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
          ],
          onDestinationSelected: controller.changeTab,
        ),
        floatingActionButton: controller.currentIndex.value == 0
            ? FloatingActionButton.extended(
                onPressed: () => Get.toNamed(AppRoutes.orders, parameters: {'mode': 'create'}),
                icon: const Icon(Icons.add),
                label: const Text('Nova OS'),
              )
            : null,
      ),
    );
  }
}

class _SyncTab extends GetView<SyncController> {
  const _SyncTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sincronização', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Obx(() => Text('Última sincronização: \${controller.lastSync.value ?? 'Nunca'}')),
          const SizedBox(height: 12),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isSyncing.value ? null : controller.sync,
                icon: controller.isSyncing.value
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: const Text('Sincronizar agora'),
              )),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: controller.processQueue,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Enviar fila offline'),
          ),
          const Divider(height: 32),
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: controller.changes.length,
                  itemBuilder: (context, index) {
                    final change = controller.changes[index];
                    return ListTile(
                      title: Text(change.entity),
                      subtitle: Text(change.operation),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}
