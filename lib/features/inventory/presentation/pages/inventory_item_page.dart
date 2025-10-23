import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/inventory_item_controller.dart';

class InventoryItemPage extends StatefulWidget {
  const InventoryItemPage({super.key});

  @override
  State<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends State<InventoryItemPage> {
  final qtyController = TextEditingController();
  late final InventoryItemController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<InventoryItemController>();
    final id = Get.parameters['id'];
    if (id != null) {
      controller.load(id);
    }
  }

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    return Scaffold(
      appBar: AppBar(title: const Text('Item de estoque')),
      body: Obx(() {
        final item = controller.item.value;
        if (controller.isLoading.value && item == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (item == null) {
          return const Center(child: Text('Item não encontrado'));
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('SKU ${item.sku}'),
              const SizedBox(height: 12),
              Text('Disponível: ${item.onHand} • Reservado: ${item.reserved}'),
              const Divider(height: 32),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: id == null
                    ? null
                    : () {
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        controller.move({'itemId': id, 'qty': qty, 'type': 'in'});
                      },
                child: const Text('Entrada'),
              ),
              ElevatedButton(
                onPressed: id == null
                    ? null
                    : () {
                        final qty = int.tryParse(qtyController.text) ?? 0;
                        controller.move({'itemId': id, 'qty': qty, 'type': 'out'});
                      },
                child: const Text('Saída'),
              ),
            ],
          ),
        );
      }),
    );
  }
}
