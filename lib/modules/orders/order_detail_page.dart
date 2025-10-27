import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
import './order_detail_controller.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/application/auth/auth_service_application.dart';

class OrderDetailPage extends GetView<OrderDetailController> {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final order = Get.arguments as OrderModel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: controller.openPdf,
          )
        ],
      ),
      body: Obx(() => Stack(children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(order: order),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar'),
                      onPressed: controller.startOrder,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Reservar materiais'),
                      onPressed: () => _openReserveDialogV2(context),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Finalizar OS'),
                  onPressed: () => _openFinishDialogV2(context),
                ),
                const SizedBox(height: 24),
                _Section(title: 'Checklist', child: _ChecklistSection()), 
                const SizedBox(height: 12),
                _Section(title: 'Evidências', child: _EvidenceSection()), 
                const SizedBox(height: 12),
                _Section(title: 'Faturamento', child: _Soon(label: 'Resumo e histórico em breve')), 
              ],
            ),
            if (controller.isLoading.value)
              const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
          ])),
    );
  }

  void _openReserveDialog(BuildContext context) {
    final itemIdCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Reservar materiais',
      content: Column(
        children: [
          TextField(controller: itemIdCtrl, decoration: const InputDecoration(labelText: 'Item ID')),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantidade'), keyboardType: TextInputType.number),
        ],
      ),
      textConfirm: 'Reservar',
      textCancel: 'Cancelar',
      onConfirm: () {
        final id = itemIdCtrl.text.trim();
        final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
        if (id.isNotEmpty && qty > 0) {
          controller.reserveMaterials([
            {'itemId': id, 'qty': qty},
          ]);
        }
        Get.back();
      },
    );
  }

  void _openFinishDialog(BuildContext context) {
    final itemIdCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: 'Serviço');
    final qtyBillCtrl = TextEditingController(text: '1');
    final unitPriceCtrl = TextEditingController(text: '0');
    final discountCtrl = TextEditingController(text: '0');
    Get.defaultDialog(
      title: 'Finalizar OS',
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text('Materiais usados'),
            TextField(controller: itemIdCtrl, decoration: const InputDecoration(labelText: 'Item ID')),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantidade'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            const Text('Faturamento'),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do item')),
            TextField(controller: qtyBillCtrl, decoration: const InputDecoration(labelText: 'Qtd'), keyboardType: TextInputType.number),
            TextField(controller: unitPriceCtrl, decoration: const InputDecoration(labelText: 'Preço unitário'), keyboardType: TextInputType.number),
            TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Desconto'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      textConfirm: 'Finalizar',
      textCancel: 'Cancelar',
      onConfirm: () {
        final materials = <Map<String, dynamic>>[];
        final mid = itemIdCtrl.text.trim();
        final mqty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
        if (mid.isNotEmpty && mqty > 0) {
          materials.add({'itemId': mid, 'qty': mqty});
        }
        final items = <Map<String, dynamic>>[
          {
            'type': 'service',
            'name': nameCtrl.text.trim(),
            'qty': double.tryParse(qtyBillCtrl.text.replaceAll(',', '.')) ?? 1,
            'unitPrice': double.tryParse(unitPriceCtrl.text.replaceAll(',', '.')) ?? 0,
          },
        ];
        final discount = double.tryParse(discountCtrl.text.replaceAll(',', '.')) ?? 0;
        controller.finishOrder(materials: materials, billingItems: items, discount: discount);
        Get.back();
      },
    );
  }
}

class _Header extends StatelessWidget {
  final OrderModel order;
  const _Header({required this.order});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.themeGray, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  [
                    if (order.scheduledAt != null) order.scheduledAt!.toLocal().toString(),
                    if (order.location != null) order.location!,
                    if (order.equipment != null) order.equipment!,
                  ].join(' • '),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusTag(status: order.status),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;
  const _StatusTag({required this.status});
  @override
  Widget build(BuildContext context) {
    final statusColor = {
      'scheduled': Colors.blueAccent,
      'in_progress': Colors.orange,
      'finished': Colors.green,
      'canceled': Colors.redAccent,
    }[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(color: statusColor)),
    );
  }
}

class _Soon extends StatelessWidget {
  final String label;
  const _Soon({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.themeGray, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ChecklistSection extends GetView<OrderDetailController> {
  final TextEditingController _textCtrl = TextEditingController();
  _ChecklistSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                decoration: const InputDecoration(labelText: 'Novo item'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                controller.addChecklistItem(_textCtrl.text);
                _textCtrl.clear();
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => Column(
              children: [
                for (int i = 0; i < controller.checklist.length; i++)
                  CheckboxListTile(
                    value: (controller.checklist[i]['checked'] as bool?) ?? false,
                    onChanged: (v) => controller.toggleChecklist(i, v ?? false),
                    title: Text(
                      controller.checklist[i]['text']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => controller.removeChecklist(i),
                    ),
                  ),
              ],
            )),
      ],
    );
  }
}

class _EvidenceSection extends GetView<OrderDetailController> {
  _EvidenceSection({super.key});
  final SignatureController _sigCtrl = SignatureController(penStrokeWidth: 3, penColor: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Adicionar arquivo'),
              onPressed: controller.addEvidenceFromPicker,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.border_color),
              label: const Text('Assinatura'),
              onPressed: () => _openSignatureDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in controller.evidences)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.themeGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(name, style: const TextStyle(color: Colors.white70)),
                  )
              ],
            )),
      ],
    );
  }

  void _openSignatureDialog(BuildContext context) {
    _sigCtrl.clear();
    Get.defaultDialog(
      title: 'Assinatura',
      content: Container(
        color: context.themeGray,
        width: Get.width * .8,
        height: 200,
        child: Signature(controller: _sigCtrl, backgroundColor: context.themeGray),
      ),
      textConfirm: 'Salvar',
      textCancel: 'Cancelar',
      onConfirm: () async {
        final bytes = await _sigCtrl.toPngBytes();
        if (bytes != null) {
          await controller.uploadSignatureBytes(bytes);
        }
        Get.back();
      },
    );
  }
}

Future<List<Map<String, dynamic>>> _pickMultipleInventoryItems() async {
  final inv = Get.find<InventoryService>();
  final auth = Get.find<AuthServiceApplication>();
  final items = await inv.getItems(auth.user.value?.id ?? '');
  final list = RxList<InventoryItemModel>(items);
  final selected = RxList<Map<String, dynamic>>([]);
  final searchCtrl = TextEditingController();

  await Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Get.context!.theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar item'),
                  onChanged: (v) {
                    final q = v.trim().toUpperCase();
                    list.assignAll(items.where((e) => e.description.toUpperCase().contains(q)));
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Concluir'),
              )
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Obx(() => ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(list[i].description),
                    subtitle: Text('Qtd: ${list[i].quantity} ${list[i].unit}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final qtyCtrl = TextEditingController(text: '1');
                        Get.defaultDialog(
                          title: 'Quantidade',
                          content: TextField(controller: qtyCtrl, keyboardType: TextInputType.number),
                          textConfirm: 'Adicionar',
                          textCancel: 'Cancelar',
                          onConfirm: () {
                            final q = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
                            if (q > 0) {
                              selected.add({'itemId': list[i].id, 'qty': q, 'desc': list[i].description});
                            }
                            Get.back();
                          },
                        );
                      },
                    ),
                  ),
                )),
          ),
          const SizedBox(height: 8),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected
                    .map((e) => Chip(
                          label: Text('${e['desc']} • ${e['qty']}'),
                          onDeleted: () => selected.remove(e),
                        ))
                    .toList(),
              )),
        ],
      ),
    ),
    isScrollControlled: true,
  );
  return selected.map((e) => {'itemId': e['itemId'], 'qty': (e['qty'] as num).toDouble()}).toList();
}

Future<void> _openReserveDialogV2(BuildContext context) async {
  final items = await _pickMultipleInventoryItems();
  if (items.isEmpty) return;
  await Get.find<OrderDetailController>().reserveMaterials(items);
}

Future<void> _openFinishDialogV2(BuildContext context) async {
  final nameCtrl = TextEditingController(text: 'Serviço');
  final qtyBillCtrl = TextEditingController(text: '1');
  final unitPriceCtrl = TextEditingController(text: '0');
  final discountCtrl = TextEditingController(text: '0');
  final usedMaterials = await _pickMultipleInventoryItems();
  if (usedMaterials.isEmpty) return;
  Get.defaultDialog(
    title: 'Finalizar OS',
    content: SingleChildScrollView(
      child: Column(
        children: [
          const Text('Faturamento'),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do item')),
          TextField(controller: qtyBillCtrl, decoration: const InputDecoration(labelText: 'Qtd'), keyboardType: TextInputType.number),
          TextField(controller: unitPriceCtrl, decoration: const InputDecoration(labelText: 'Preço unitário'), keyboardType: TextInputType.number),
          TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Desconto'), keyboardType: TextInputType.number),
        ],
      ),
    ),
    textConfirm: 'Finalizar',
    textCancel: 'Cancelar',
    onConfirm: () {
      final items = <Map<String, dynamic>>[
        {
          'type': 'service',
          'name': nameCtrl.text.trim(),
          'qty': double.tryParse(qtyBillCtrl.text.replaceAll(',', '.')) ?? 1,
          'unitPrice': double.tryParse(unitPriceCtrl.text.replaceAll(',', '.')) ?? 0,
        },
      ];
      final discount = double.tryParse(discountCtrl.text.replaceAll(',', '.')) ?? 0;
      Get.find<OrderDetailController>().finishOrder(materials: usedMaterials, billingItems: items, discount: discount);
      Get.back();
    },
  );
}
