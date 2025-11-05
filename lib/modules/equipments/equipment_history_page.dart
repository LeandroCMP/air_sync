import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'equipment_history_controller.dart';

class EquipmentHistoryPage extends GetView<EquipmentHistoryController> {
  const EquipmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Histórico de manutenção', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Relatório (PDF)',
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            onPressed: controller.exportPdf,
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LinearProgressIndicator(minHeight: 2);
        if (controller.items.isEmpty) {
          return const Center(child: Text('Sem registros', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final m = controller.items[i];
            final typeRaw = (m['type'] ?? '').toString();
            final type = _typeLabel(typeRaw);
            final orderId = (m['orderId'] ?? '').toString();
            final atRaw = m['at'];
            final at = atRaw is String ? DateTime.tryParse(atRaw) : (atRaw is DateTime ? atRaw : null);
            final when = at != null ? _formatDateTime(at) : '-';
            final notes = (m['notes'] ?? '').toString();
            return ListTile(
              title: Text('$when • $type', style: const TextStyle(color: Colors.white)),
              subtitle: Text([
                if (orderId.isNotEmpty) 'OS: ' + orderId,
                if (notes.isNotEmpty) notes,
              ].join('  •  '), style: const TextStyle(color: Colors.white70)),
            );
          },
        );
      }),
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'order_created':
        return 'OS criada';
      case 'order_finished':
        return 'OS finalizada';
      case 'moved':
        return 'Movido';
      case 'replaced':
        return 'Substituído';
      default:
        return t.isEmpty ? '-' : t;
    }
  }

  // Histórico vem da API (eventos de OS); sem inclusão manual nesta tela.
  String _formatDateTime(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return dd + '/' + m + '/' + y + ' ' + hh + ':' + mm;
  }
}

