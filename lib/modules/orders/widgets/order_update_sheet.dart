import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderUpdateResult {
  OrderUpdateResult({
    this.status,
    this.scheduledAt,
    this.technicianIds,
    this.notes,
  });

  final String? status;
  final DateTime? scheduledAt;
  final List<String>? technicianIds;
  final String? notes;
}

Future<OrderUpdateResult?> showOrderUpdateSheet({
  required BuildContext context,
  required OrderModel order,
  required List<CollaboratorModel> technicians,
}) {
  return showModalBottomSheet<OrderUpdateResult>(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => _OrderUpdateSheet(order: order, technicians: technicians),
  );
}

class _OrderUpdateSheet extends StatelessWidget {
  const _OrderUpdateSheet({required this.order, required this.technicians});

  final OrderModel order;
  final List<CollaboratorModel> technicians;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GetBuilder<OrderUpdateSheetController>(
        init: OrderUpdateSheetController(
          order: order,
          technicians: technicians,
        ),
        builder: (controller) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.theme.dialogBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Atualizar dados da OS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: controller.status.value,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'scheduled',
                                  child: Text('Agendada'),
                                ),
                                DropdownMenuItem(
                                  value: 'in_progress',
                                  child: Text('Em andamento'),
                                ),
                                DropdownMenuItem(
                                  value: 'done',
                                  child: Text('Concluída'),
                                ),
                                DropdownMenuItem(
                                  value: 'canceled',
                                  child: Text('Cancelada'),
                                ),
                              ],
                              onChanged: controller.changeStatus,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Agendamento',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                    label: Text(
                                      controller.scheduledLabel ??
                                          'Definir data',
                                    ),
                                    onPressed: () =>
                                        controller.pickDateTime(context),
                                  ),
                                ),
                                if (controller.hasSchedule) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Limpar horário',
                                    icon: const Icon(Icons.clear),
                                    onPressed: controller.clearSchedule,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (controller.hasTechnicians) ...[
                              Text(
                                'Técnicos',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    controller.technicians.map((tech) {
                                      final selected =
                                          controller.isTechSelected(tech.id);
                                      return FilterChip(
                                        label: Text(tech.name),
                                        selected: selected,
                                        onSelected:
                                            (_) => controller.toggleTechnician(
                                              tech.id,
                                            ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextField(
                              controller: controller.notesCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Observações',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(
                              controller.buildResult(),
                            ),
                            child: const Text('Salvar alterações'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrderUpdateSheetController extends GetxController {
  OrderUpdateSheetController({
    required this.order,
    required this.technicians,
  }) {
    status.value = order.status;
    scheduledAt.value = order.scheduledAt;
    selectedTechs.assignAll(order.technicianIds);
    notesCtrl.text = order.notes ?? '';
  }

  final OrderModel order;
  final List<CollaboratorModel> technicians;

  final RxnString status = RxnString();
  final Rxn<DateTime> scheduledAt = Rxn<DateTime>();
  final RxList<String> selectedTechs = <String>[].obs;
  final TextEditingController notesCtrl = TextEditingController();
  final DateFormat _formatter = DateFormat('dd/MM/yyyy HH:mm');

  bool get hasTechnicians => technicians.isNotEmpty;
  bool get hasSchedule => scheduledAt.value != null;

  String? get scheduledLabel =>
      scheduledAt.value == null ? null : _formatter.format(scheduledAt.value!);

  void changeStatus(String? value) {
    status.value = value;
    update();
  }

  Future<void> pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initial = scheduledAt.value ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selectedDate == null) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (selectedTime == null) return;
    scheduledAt.value = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    update();
  }

  void clearSchedule() {
    scheduledAt.value = null;
    update();
  }

  bool isTechSelected(String id) => selectedTechs.contains(id);

  void toggleTechnician(String id) {
    if (selectedTechs.contains(id)) {
      selectedTechs.remove(id);
    } else {
      selectedTechs.add(id);
    }
    update();
  }

  OrderUpdateResult buildResult() {
    final noteText = notesCtrl.text.trim();
    return OrderUpdateResult(
      status: status.value,
      scheduledAt: scheduledAt.value,
      technicianIds: selectedTechs.toList(),
      notes: noteText.isEmpty ? null : noteText,
    );
  }

  @override
  void onClose() {
    notesCtrl.dispose();
    super.onClose();
  }
}
