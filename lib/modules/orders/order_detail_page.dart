import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './order_detail_controller.dart';

class OrderDetailPage extends GetView<OrderDetailController> {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _openPdf(controller),
          ),
        ],
      ),
      body: Obx(() {
        final order = controller.order.value;
        if (order == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(order: order),
              const SizedBox(height: 16),
              _SectionTitle('Checklist'),
              if (order.checklist.isEmpty)
                const Text(
                  'Sem itens cadastrados.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...order.checklist.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item.done ? Icons.check_circle : Icons.radio_button_off,
                      color: item.done ? context.themeGreen : Colors.white38,
                    ),
                    title: Text(
                      item.item,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle:
                        item.note == null
                            ? null
                            : Text(
                              item.note!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                  ),
                ),
              const SizedBox(height: 20),
              _SectionTitle('Materiais'),
              if (order.materials.isEmpty)
                const Text(
                  'Nenhum material vinculado.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...order.materials.map(
                  (material) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      material.itemName ?? material.itemId,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Qtd: ${material.qty} • Reservado: ${material.reserved ? 'Sim' : 'Não'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _SectionTitle('Cobrança'),
              if (order.billing.items.isEmpty)
                const Text(
                  'Sem itens de cobrança.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.billing.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${item.type == 'service' ? 'Serviço' : 'Peça'} • ${item.qty} x R\$ ${item.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          'R\$ ${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const Divider(),
                    _BillingSummary(order.billing),
                  ],
                ),
              const SizedBox(height: 24),
              _Actions(controller: controller, order: order),
            ],
          ),
        );
      }),
    );
  }

  void _openPdf(OrderDetailController controller) {
    final url = controller.pdfUrl();
    Get.toNamed('/pdf/viewer', arguments: url);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(order.status);
    return Card(
      color: context.themeDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: status.color.withOpacity(.15),
                  foregroundColor: status.color,
                  child: Icon(status.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName ?? 'Cliente não informado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow('Local', order.locationLabel),
            _InfoRow('Equipamento', order.equipmentLabel),
            _InfoRow(
              'Agendada para',
              order.scheduledAt?.toLocal().toString().replaceFirst('T', ' às '),
            ),
            _InfoRow('Início', order.startedAt?.toLocal().toString()),
            _InfoRow('Conclusão', order.finishedAt?.toLocal().toString()),
            if (order.notes != null && order.notes!.isNotEmpty)
              _InfoRow('Observações', order.notes),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _BillingSummary extends StatelessWidget {
  const _BillingSummary(this.billing);

  final OrderBilling billing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _summaryRow('Subtotal', billing.subtotal),
        _summaryRow('Desconto', -billing.discount),
        const SizedBox(height: 6),
        _summaryRow('Total', billing.total, emphasize: true),
      ],
    );
  }

  Widget _summaryRow(String label, num value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.controller, required this.order});

  final OrderDetailController controller;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar OS'),
          onPressed:
              order.isInProgress || order.isDone ? null : controller.startOrder,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Atualizar dados'),
          onPressed: controller.load,
        ),
      ],
    );
  }
}

_StatusItem _statusFor(String value) {
  if (value == 'scheduled') {
    return const _StatusItem(
      label: 'Agendada',
      color: Colors.blueAccent,
      icon: Icons.event_available,
    );
  }
  if (value == 'in_progress') {
    return const _StatusItem(
      label: 'Em andamento',
      color: Colors.orange,
      icon: Icons.build,
    );
  }
  if (value == 'done') {
    return const _StatusItem(
      label: 'Concluída',
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }
  if (value == 'canceled') {
    return const _StatusItem(
      label: 'Cancelada',
      color: Colors.redAccent,
      icon: Icons.cancel,
    );
  }
  return const _StatusItem(
    label: 'Indefinido',
    color: Colors.white54,
    icon: Icons.help_outline,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}
