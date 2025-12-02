import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'timeline_controller.dart';

class TimelinePage extends GetView<TimelineController> {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Timeline', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openAddDialog(context),
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LinearProgressIndicator(minHeight: 2);
        if (controller.items.isEmpty) {
          return const Center(child: Text('Sem interações', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final e = controller.items[i];
            final icon = _iconForType(e.type);
            return ListTile(
              leading: Icon(icon, color: Colors.white70),
              title: Text(e.text, style: const TextStyle(color: Colors.white)),
              subtitle: Text('${e.type} • ${e.at.toLocal()}', style: const TextStyle(color: Colors.white70)),
            );
          },
        );
      }),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'call':
        return Icons.call_outlined;
      case 'whatsapp':
        return Icons.chat_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'nps':
        return Icons.emoji_emotions_outlined;
      case 'note':
      default:
        return Icons.note_alt_outlined;
    }
  }

  void _openAddDialog(BuildContext context) {
    final textCtrl = TextEditingController();
    final types = const [
      DropdownMenuItem(value: 'note', child: Text('Nota')),
      DropdownMenuItem(value: 'call', child: Text('Ligação')),
      DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
      DropdownMenuItem(value: 'email', child: Text('Email')),
      DropdownMenuItem(value: 'nps', child: Text('NPS')),
    ];
    String type = 'note';
    Get.defaultDialog(
      title: 'Adicionar interação',
      content: StatefulBuilder(builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: type,
              items: types,
              onChanged: (v) => setState(() => type = (v ?? 'note')),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        );
      }),
      confirm: ElevatedButton(
        onPressed: () async {
          final text = textCtrl.text.trim();
          if (text.isEmpty) return;
          await controller.addQuick(type, text);
          Get.back();
        },
        child: const Text('Salvar'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
    );
  }
}
