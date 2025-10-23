import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/widgets/buttons.dart';
import '../../../../app/widgets/status_tag.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_detail_controller.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final clientId = TextEditingController();
  final locationId = TextEditingController();
  final equipmentId = TextEditingController();
  final scheduledAt = TextEditingController();

  final materialsController = TextEditingController();

  late final OrderDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OrderDetailController>();
    final id = Get.parameters['id'];
    if (id != null) {
      controller.load(id);
    }
  }

  @override
  void dispose() {
    clientId.dispose();
    locationId.dispose();
    equipmentId.dispose();
    scheduledAt.dispose();
    materialsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'];
    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? 'Nova OS' : 'Detalhes da OS'),
        actions: [
          if (id != null)
            TextButton(
              onPressed: () => controller.start(id),
              child: const Text('Iniciar'),
            ),
        ],
      ),
      body: Obx(() {
        final order = controller.order.value;
        if (controller.isLoading.value && order == null && id != null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order != null)
                  Row(
                    children: [
                      StatusTag(label: order.status),
                      const SizedBox(width: 12),
                      if (order.scheduledAt != null)
                        Text('Agendado para ${order.scheduledAt}'),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: clientId,
                  decoration: const InputDecoration(labelText: 'Cliente ID'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationId,
                  decoration: const InputDecoration(labelText: 'Local ID'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: equipmentId,
                  decoration: const InputDecoration(labelText: 'Equipamento ID'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: scheduledAt,
                  decoration: const InputDecoration(labelText: 'Data agendada (ISO8601)'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Salvar',
                  onPressed: () async {
                    final payload = {
                      'clientId': clientId.text,
                      'locationId': locationId.text,
                      'equipmentId': equipmentId.text,
                      'scheduledAt': scheduledAt.text,
                    };
                    final saved = await controller.save(id: id, payload: payload);
                    if (saved != null) {
                      Get.back(result: saved);
                    }
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: materialsController,
                  decoration: const InputDecoration(
                    labelText: 'Materiais (JSON)',
                    helperText: '[{"itemId":"...","qty":1}]',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Reservar materiais',
                        onPressed: id == null
                            ? null
                            : () {
                                final items = _parseMaterials();
                                controller.reserveMaterials(id, items);
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Baixar materiais',
                        onPressed: id == null
                            ? null
                            : () {
                                final items = _parseMaterials();
                                controller.deductMaterials(id, items);
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (id != null)
                  PrimaryButton(
                    label: 'Finalizar OS',
                    onPressed: () {
                      final payload = {
                        'materials': _parseMaterials(),
                        'billing': {
                          'items': [
                            {'type': 'service', 'name': 'Serviço executado', 'qty': 1, 'unitPrice': 0},
                          ],
                          'discount': 0,
                          'total': 0,
                        },
                      };
                      controller.finish(id, payload);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  List<Map<String, dynamic>> _parseMaterials() {
    final text = materialsController.text.trim();
    if (text.isEmpty) {
      return [];
    }
    try {
      final parsed = GetUtils.isJSON(text) ? (GetUtils.jsonDecode(text) as List<dynamic>) : <dynamic>[];
      return parsed.cast<Map<String, dynamic>>();
    } catch (_) {
      Get.snackbar('Erro', 'JSON inválido');
      return [];
    }
  }
}
