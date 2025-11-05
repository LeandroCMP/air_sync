import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'order_create_controller.dart';

class OrderCreatePage extends GetView<OrderCreateController> {
  const OrderCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Ordem de Serviço')),
      body: Form(
        key: controller.formKey,
        child: Obx(() {
          final blocking = controller.isLoading.value;
          final inventoryLoading = controller.isInventoryLoading.value;
          final inventoryError = controller.inventoryError.value;
          final inventoryItems = controller.inventoryItems.toList(
            growable: false,
          );
          final materials = controller.materials.toList(growable: false);
          final billingItems = controller.billingItems.toList(growable: false);
          final checklist = controller.checklist.toList(growable: false);
          final scheduledAt = controller.scheduledAt.value;

          return Stack(
            children: [
              IgnorePointer(
                ignoring: blocking,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        title: 'Dados principais',
                        child: Column(
                          children: [
                            _ClientDropdown(controller: controller),
                            const SizedBox(height: 12),
                            _LocationDropdown(controller: controller),
                            const SizedBox(height: 12),
                            _EquipmentDropdown(controller: controller),
                            const SizedBox(height: 12),
                            _ScheduledField(
                              controller: controller,
                              scheduledAt: scheduledAt,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: controller.techniciansCtrl,
                              decoration: const InputDecoration(
                                labelText:
                                    'Técnicos (IDs separados por vírgula)',
                                helperText:
                                    'Opcional. Informe apenas quando precisar atribuir técnicos específicos.',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: controller.notesCtrl,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Observações internas',
                                helperText:
                                    'Essas informações ficam visíveis para a equipe.',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Checklist inicial',
                        action: TextButton.icon(
                          onPressed: controller.addChecklistItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar item'),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: controller.checklistCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Novo item',
                                hintText: 'Ex.: Verificar pressão do gás',
                              ),
                              style: const TextStyle(color: Colors.white),
                              onSubmitted: (_) => controller.addChecklistItem(),
                            ),
                            const SizedBox(height: 12),
                            if (checklist.isEmpty)
                              const Text(
                                'Nenhum item adicionado. Utilize a caixa acima para criar o checklist inicial.',
                                style: TextStyle(color: Colors.white70),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  checklist.length,
                                  (index) => Chip(
                                    label: Text(checklist[index]),
                                    deleteIconColor: Colors.white70,
                                    onDeleted:
                                        () => controller.removeChecklistItem(
                                          index,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Materiais a reservar',
                        action: OutlinedButton.icon(
                          onPressed: controller.addMaterialRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar material'),
                        ),
                        child: Column(
                          children: [
                            if (inventoryLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (inventoryError != null)
                              _InlineMessage(
                                type: _InlineMessageType.error,
                                text: inventoryError,
                                actionLabel: 'Tentar novamente',
                                onAction: controller.refreshInventory,
                              )
                            else if (inventoryItems.isEmpty)
                              _InlineMessage(
                                type: _InlineMessageType.info,
                                text:
                                    'Nenhum item ativo disponível. Cadastre itens ou atualize o filtro.',
                                actionLabel: 'Recarregar',
                                onAction: controller.refreshInventory,
                              ),
                            ...List.generate(
                              materials.length,
                              (index) => _MaterialRow(
                                entry: materials[index],
                                index: index,
                                items: inventoryItems,
                                onRemove:
                                    () => controller.removeMaterialRow(index),
                              ),
                            ),
                            if (materials.isEmpty && inventoryItems.isNotEmpty)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Nenhum material selecionado para esta OS.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Cobrança (opcional)',
                        action: OutlinedButton.icon(
                          onPressed: controller.addBillingRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar item'),
                        ),
                        child: Column(
                          children: [
                            ...List.generate(
                              billingItems.length,
                              (index) => _BillingRow(
                                entry: billingItems[index],
                                index: index,
                                onRemove:
                                    () => controller.removeBillingRow(index),
                              ),
                            ),
                            if (billingItems.isEmpty)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Nenhum item de cobrança informado.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: controller.discountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Desconto (R\$)',
                                helperText:
                                    'Opcional. Caso não haja desconto, deixe em branco.',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: controller.submit,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text(
                            'Criar Ordem de Serviço',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (blocking)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ClientDropdown extends StatelessWidget {
  const _ClientDropdown({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = controller.clients;
      return DropdownButtonFormField<String>(
        value: controller.selectedClientId.value,
        isExpanded: true,
        dropdownColor: context.themeSurfaceAlt,
        decoration: const InputDecoration(labelText: 'Cliente *'),
        style: TextStyle(color: context.themeTextMain),
        items:
            options
                .map(
                  (client) => DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
        onChanged: (value) => controller.onClientSelected(value),
        validator: (value) => value == null ? 'Selecione o cliente' : null,
      );
    });
  }
}

class _LocationDropdown extends StatelessWidget {
  const _LocationDropdown({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = controller.locations;
      return DropdownButtonFormField<String>(
        value: controller.selectedLocationId.value,
        isExpanded: true,
        dropdownColor: context.themeSurfaceAlt,
        decoration: const InputDecoration(labelText: 'Local *'),
        style: TextStyle(color: context.themeTextMain),
        items:
            options
                .map(
                  (location) => DropdownMenuItem(
                    value: location.id,
                    child: Text(
                      _locationLabel(location),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged:
            options.isEmpty
                ? null
                : (value) => controller.onLocationSelected(value),
        validator: (value) => value == null ? 'Selecione o local' : null,
      );
    });
  }

  String _locationLabel(LocationModel model) {
    final parts = <String>[];
    if (model.label.isNotEmpty) parts.add(model.label);
    if ((model.addressLine).isNotEmpty) parts.add(model.addressLine);
    if (model.cityState.isNotEmpty) parts.add(model.cityState);
    return parts.join(' • ');
  }
}

class _EquipmentDropdown extends StatelessWidget {
  const _EquipmentDropdown({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = controller.equipments;
      return DropdownButtonFormField<String>(
        value: controller.selectedEquipmentId.value,
        isExpanded: true,
        dropdownColor: context.themeSurfaceAlt,
        decoration: const InputDecoration(labelText: 'Equipamento (opcional)'),
        style: TextStyle(color: context.themeTextMain),
        items:
            options
                .map(
                  (equipment) => DropdownMenuItem(
                    value: equipment.id,
                    child: Text(
                      _equipmentLabel(equipment),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        onChanged: options.isEmpty ? null : controller.setEquipment,
      );
    });
  }

  String _equipmentLabel(EquipmentModel equipment) {
    final parts = <String>[];
    if ((equipment.room ?? '').isNotEmpty) parts.add(equipment.room!);
    if ((equipment.brand ?? '').isNotEmpty) parts.add(equipment.brand!);
    if ((equipment.model ?? '').isNotEmpty) parts.add(equipment.model!);
    return parts.isEmpty ? equipment.id : parts.join(' • ');
  }
}

class _ScheduledField extends StatelessWidget {
  const _ScheduledField({required this.controller, required this.scheduledAt});

  final OrderCreateController controller;
  final DateTime? scheduledAt;

  @override
  Widget build(BuildContext context) {
    final current = scheduledAt;
    final text =
        current == null
            ? 'Selecionar data e hora (opcional)'
            : DateFormat('dd/MM/yyyy HH:mm').format(current.toLocal());
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickDateTime(context),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Agendamento'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(text, style: TextStyle(color: context.themeTextMain)),
                  const Icon(Icons.event, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
        if (scheduledAt != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Limpar data',
            onPressed: controller.clearScheduledAt,
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = scheduledAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledAt ?? now),
    );
    if (!context.mounted) return;
    if (time == null) {
      controller.setScheduledAt(DateTime(date.year, date.month, date.day));
      return;
    }
    controller.setScheduledAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.entry,
    required this.index,
    required this.items,
    required this.onRemove,
  });

  final OrderMaterialDraft entry;
  final int index;
  final List<InventoryItemModel> items;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasItems = items.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Material ${index + 1}',
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remover material',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              value: entry.itemId.value,
              isExpanded: true,
              dropdownColor: context.themeSurface,
              decoration: const InputDecoration(labelText: 'Item do estoque'),
              style: TextStyle(color: context.themeTextMain),
              items:
                  items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            _inventoryLabel(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged:
                  hasItems ? (value) => entry.itemId.value = value : null,
              validator: (value) {
                if (!hasItems) return null;
                return value == null ? 'Selecione o item' : null;
              },
            ),
          ),
          if (!hasItems)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Nenhum item disponível no momento.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantidade'),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _inventoryLabel(InventoryItemModel item) {
    final buffer = StringBuffer(item.name);
    if (item.sku.isNotEmpty) buffer.write(' • ${item.sku}');
    buffer.write(' • Saldo: ${item.onHand.toStringAsFixed(2)}');
    return buffer.toString();
  }
}

class _BillingRow extends StatelessWidget {
  const _BillingRow({
    required this.entry,
    required this.index,
    required this.onRemove,
  });

  final OrderBillingDraft entry;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remover item',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => DropdownButtonFormField<String>(
              value: entry.type.value,
              isExpanded: true,
              dropdownColor: context.themeSurface,
              decoration: const InputDecoration(labelText: 'Tipo'),
              style: TextStyle(color: context.themeTextMain),
              items: const [
                DropdownMenuItem(value: 'service', child: Text('Serviço')),
                DropdownMenuItem(value: 'part', child: Text('Peça')),
              ],
              onChanged:
                  (value) => entry.type.value = value ?? entry.type.value,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.nameCtrl,
            decoration: const InputDecoration(labelText: 'Descrição'),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: entry.unitPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor unitário (R\$)',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _InlineMessageType { info, error }

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.type,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final _InlineMessageType type;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final icon =
        type == _InlineMessageType.error ? Icons.error_outline : Icons.info;
    final color =
        type == _InlineMessageType.error
            ? context.themeWarning
            : context.themeInfo;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(color: context.themeTextMain, height: 1.3),
                ),
                if (actionLabel != null && onAction != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
