import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sync_controller.dart';

class SyncPage extends GetView<SyncController> {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronização')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text('Última sincronização: ${controller.lastSync.value ?? 'Nunca'}')),
            const SizedBox(height: 12),
            Obx(() => ElevatedButton.icon(
                  onPressed: controller.isSyncing.value ? null : controller.sync,
                  icon: controller.isSyncing.value ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
                  label: const Text('Sincronizar agora'),
                )),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: controller.processQueue,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Enviar fila offline'),
            ),
            const Divider(height: 32),
            const Text('Alterações recentes'),
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
            Obx(() {
              if (controller.error.value == null) {
                return const SizedBox.shrink();
              }
              return Text(controller.error.value!, style: TextStyle(color: Theme.of(context).colorScheme.error));
            }),
          ],
        ),
      ),
    );
  }
}
