import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/cost_center_model.dart';
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
      appBar: AppBar(title: const Text('Nova Ordem de Servico')),
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
                        subtitle: 'Cliente, local, agendamento e equipe',
                        icon: Icons.assignment_outlined,
                        child: Column(
                          children: [
                            _ClientSelector(controller: controller),
                            const SizedBox(height: 12),
                            _LocationSelector(controller: controller),
                            const SizedBox(height: 12),
                            _EquipmentSelector(controller: controller),
                            const SizedBox(height: 12),
                            _ScheduledField(
                              controller: controller,
                              scheduledAt: scheduledAt,
                            ),
                            const SizedBox(height: 12),
                            _TechnicianSelector(controller: controller),
                            const SizedBox(height: 12),
                            _CostCenterSelector(controller: controller),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: controller.notesCtrl,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Observacoes internas',
                                helperText:
                                    'Essas informacoes ficam visiveis para a equipe.',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Checklist inicial',
                        subtitle: 'Monte o passo a passo que o técnico verá',
                        icon: Icons.fact_check_outlined,
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
                                hintText: 'Ex.: Verificar pressao do gas',
                              ),
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
                        subtitle: 'Selecione itens do estoque e defina a saída prevista',
                        icon: Icons.inventory_2_outlined,
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
                            if (materials.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Nenhum material adicionado. Utilize o botão acima para incluir itens opcionais.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ),
                            ...List.generate(
                              materials.length,
                              (index) => _MaterialRow(
                                controller: controller,
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
                        title: 'Cobranca (opcional)',
                        subtitle: 'Antecipe itens faturados e descontos da OS',
                        icon: Icons.payments_outlined,
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
                                  'Nenhum item de cobranca informado.',
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
                                    'Opcional. Caso nao haja desconto, deixe em branco.',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: Obx(
                          () =>
                              controller.isEditingDraft
                                  ? Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              controller.saveDraftLocally,
                                          icon: const Icon(
                                            Icons.save_alt_outlined,
                                          ),
                                          label: const Text(
                                            'Atualizar rascunho',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed:
                                              controller.deleteDraftLocally,
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Excluir rascunho'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : OutlinedButton.icon(
                                    onPressed: controller.saveDraftLocally,
                                    icon: const Icon(Icons.save_alt_outlined),
                                    label: const Text('Salvar rascunho local'),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: controller.submit,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text(
                            'Criar Ordem de Servico',
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
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final baseColor = context.themeSurface;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withValues(alpha: 0.95),
            baseColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: context.shadowCard,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    child: Icon(icon, color: Colors.white70, size: 18),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.themeTextMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 20, color: Colors.white12),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ClientSelector extends StatelessWidget {
  const _ClientSelector({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = controller.selectedClientId.value;
      final options = controller.clients.toList(growable: false);
      ClientModel? selected;
      for (final client in options) {
        if (client.id == selectedId) {
          selected = client;
          break;
        }
      }
      return FormField<String>(
        validator: (_) => selectedId == null ? 'Selecione o cliente' : null,
        builder: (state) {
          _syncFormFieldValue(state, selectedId);
          return _SelectorTile(
            label: 'Cliente *',
            value: selected?.name,
            placeholder: 'Selecionar cliente',
            helperText: options.isEmpty ? 'Nenhum cliente encontrado.' : null,
            errorText: state.errorText,
            onTap:
                options.isEmpty
                    ? null
                    : () async {
                      final picked = await _SinglePickerModal.show<ClientModel>(
                        context: context,
                        title: 'Selecionar cliente',
                        items: options,
                        initialId: selectedId,
                        id: (client) => client.id,
                        titleBuilder: (client) => client.name,
                        subtitleBuilder: (client) {
                          if ((client.docNumber ?? '').isNotEmpty) {
                            return client.docNumber!;
                          }
                          return client.primaryPhone;
                        },
                      );
                      if (picked != null) {
                        controller.onClientSelected(picked.id);
                        state.didChange(picked.id);
                      }
                    },
            onClear:
                selectedId == null
                    ? null
                    : () {
                      controller.onClientSelected(null);
                      state.didChange(null);
                    },
          );
        },
      );
    });
  }
}

class _LocationSelector extends StatelessWidget {
  const _LocationSelector({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasClient = controller.selectedClientId.value != null;
      final options = controller.locations.toList(growable: false);
      final selectedId = controller.selectedLocationId.value;
      LocationModel? selected;
      for (final location in options) {
        if (location.id == selectedId) {
          selected = location;
          break;
        }
      }

      return FormField<String>(
        validator: (_) => selectedId == null ? 'Selecione o local' : null,
        builder: (state) {
          _syncFormFieldValue(state, selectedId);
          final enableSelection = hasClient && options.isNotEmpty;
          final helper =
              !hasClient
                  ? 'Selecione um cliente para listar os locais.'
                  : options.isEmpty
                  ? 'Nenhum local cadastrado para este cliente.'
                  : null;
          return _SelectorTile(
            label: 'Local *',
            value: selected != null ? _locationDescription(selected) : null,
            placeholder:
                hasClient ? 'Selecionar local' : 'Cliente nao selecionado',
            helperText: helper,
            errorText: state.errorText,
            enabled: enableSelection,
            onTap:
                !enableSelection
                    ? null
                    : () async {
                      final picked =
                          await _SinglePickerModal.show<LocationModel>(
                            context: context,
                            title: 'Selecionar local',
                            items: options,
                            initialId: selectedId,
                            id: (location) => location.id,
                            titleBuilder: _locationDescription,
                            subtitleBuilder:
                                (location) => (location.notes ?? '').trim(),
                          );
                      if (picked != null) {
                        controller.onLocationSelected(picked.id);
                        state.didChange(picked.id);
                      }
                    },
            onClear:
                selectedId == null
                    ? null
                    : () {
                      controller.onLocationSelected(null);
                      state.didChange(null);
                    },
          );
        },
      );
    });
  }
}

class _EquipmentSelector extends StatelessWidget {
  const _EquipmentSelector({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final options = controller.equipments.toList(growable: false);
      final selectedId = controller.selectedEquipmentId.value;
      EquipmentModel? selected;
      for (final equipment in options) {
        if (equipment.id == selectedId) {
          selected = equipment;
          break;
        }
      }
      return _SelectorTile(
        label: 'Equipamento',
        value: selected != null ? _equipmentDescription(selected) : null,
        placeholder:
            options.isEmpty
                ? 'Nenhum equipamento cadastrado'
                : 'Selecionar equipamento (opcional)',
        helperText:
            options.isEmpty
                ? 'Cadastre equipamentos para este cliente/local.'
                : null,
        onTap:
            options.isEmpty
                ? null
                : () async {
                  final picked = await _SinglePickerModal.show<EquipmentModel>(
                    context: context,
                    title: 'Selecionar equipamento',
                    items: options,
                    initialId: selectedId,
                    id: (equipment) => equipment.id,
                    titleBuilder: _equipmentDescription,
                    subtitleBuilder:
                        (equipment) => (equipment.serial ?? '').trim(),
                  );
                  if (picked != null) {
                    controller.setEquipment(picked.id);
                  }
                },
        onClear:
            selectedId == null ? null : () => controller.setEquipment(null),
      );
    });
  }
}

class _TechnicianSelector extends StatelessWidget {
  const _TechnicianSelector({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final technicians = controller.technicians.toList(growable: false);
      final selected = controller.selectedTechnicians;
      final selectedIds = controller.selectedTechnicianIds.toList(
        growable: false,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectorTile(
            label: 'Tecnicos',
            value:
                selected.isEmpty
                    ? null
                    : selected.map((tech) => tech.name).join(', '),
            placeholder: 'Selecionar tecnicos (opcional)',
            helperText:
                technicians.isEmpty
                    ? 'Nenhum tecnico ativo encontrado.'
                    : 'Opcional. Atribua tecnicos responsaveis pela OS.',
            onTap:
                technicians.isEmpty
                    ? null
                    : () async {
                      final picked = await _TechnicianPickerModal.show(
                        context: context,
                        technicians: technicians,
                        initialSelection: selectedIds,
                      );
                      if (picked != null) {
                        controller.setTechnicians(picked);
                      }
                    },
            onClear:
                selected.isEmpty ? null : () => controller.setTechnicians([]),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  selected
                      .map(
                        (tech) => InputChip(
                          label: Text(tech.name),
                          onDeleted: () => controller.removeTechnician(tech.id),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      );
    });
  }
}

class _CostCenterSelector extends StatelessWidget {
  const _CostCenterSelector({required this.controller});

  final OrderCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.costCentersLoading.value;
      final options = controller.costCenters.toList(growable: false);
      final selectedId = controller.selectedCostCenterId.value;
      CostCenterModel? selected;
      for (final center in options) {
        if (center.id == selectedId) {
          selected = center;
          break;
        }
      }

      final helper =
          loading
              ? 'Carregando centros de custo...'
              : options.isEmpty
              ? 'Nenhum centro de custo ativo encontrado.'
              : 'Opcional. Use para classificar o custo desta OS.';
      final enabled = !loading && options.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectorTile(
            label: 'Centro de custo',
            value: selected?.name,
            placeholder:
                loading ? 'Carregando...' : 'Selecionar centro de custo',
            helperText: helper,
            enabled: enabled,
            onTap:
                !enabled
                    ? null
                    : () async {
                      final picked =
                          await _SinglePickerModal.show<CostCenterModel>(
                            context: context,
                            title: 'Selecionar centro de custo',
                            items: options,
                            initialId: selectedId,
                            id: (center) => center.id,
                            titleBuilder: (center) => center.name,
                            subtitleBuilder:
                                (center) => (center.code ?? '').trim().isEmpty
                                    ? center.id
                                    : center.code!,
                          );
                      if (picked != null) {
                        controller.setCostCenter(picked.id);
                      }
                    },
            onClear:
                selectedId == null ? null : () => controller.setCostCenter(null),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      );
    });
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
    required this.controller,
    required this.entry,
    required this.index,
    required this.items,
    required this.onRemove,
  });

  final OrderCreateController controller;
  final OrderMaterialDraft entry;
  final int index;
  final List<InventoryItemModel> items;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasItems = controller.inventoryItems.isNotEmpty || items.isNotEmpty;
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
                  'Material ',
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
          FormField<String>(
            validator: (_) {
              if (!hasItems) return null;
              final selectedId = entry.itemId.value;
              final qtyText = entry.qtyCtrl.text.replaceAll(',', '.').trim();
              final qty = double.tryParse(qtyText);
              final hasQty = qty != null && qty > 0;
              if (!hasQty && (selectedId == null || selectedId.isEmpty)) {
                return null;
              }
              if ((selectedId ?? '').isEmpty) {
                return 'Selecione o item';
              }
              if (!hasQty) {
                return 'Informe a quantidade';
              }
              return null;
            },
            builder: (state) {
              return Obx(() {
                final selectedId = entry.itemId.value;
                _syncFormFieldValue(state, selectedId);
                final source =
                    controller.inventoryItems.isNotEmpty
                        ? controller.inventoryItems
                        : items;
                InventoryItemModel? selected;
                for (final item in source) {
                  if (item.id == selectedId) {
                    selected = item;
                    break;
                  }
                }
                return _SelectorTile(
                  label: 'Item do estoque',
                  value: selected != null ? _inventoryValue(selected) : null,
                  placeholder:
                      hasItems ? 'Selecionar item' : 'Nenhum item disponivel',
                  helperText:
                      hasItems
                          ? null
                          : 'Sem itens ativos. Recarregue ou cadastre novos itens.',
                  errorText: state.errorText,
                  enabled: hasItems,
                  onTap: () async {
                    if (!await controller.ensureInventoryLoaded()) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nenhum item de estoque disponível no momento.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    final list = controller.inventoryItems.toList();
                    if (list.isEmpty) return;
                    final picked =
                        await _SinglePickerModal.show<InventoryItemModel>(
                          context: context,
                          title: 'Selecionar item do estoque',
                          items: list,
                          initialId: selectedId,
                          id: (item) => item.id,
                          titleBuilder: (item) => item.name,
                          subtitleBuilder: _inventorySummary,
                        );
                    if (!context.mounted) return;
                    if (picked != null) {
                      controller.setMaterialItem(index, picked);
                      state.didChange(picked.id);
                    }
                  },
                  onClear:
                      selectedId == null
                          ? null
                          : () {
                            controller.setMaterialItem(index, null);
                            state.didChange(null);
                          },
                );
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: entry.unitPriceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor de venda',
                    helperText: 'Usado para precificar materiais',
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
                DropdownMenuItem(value: 'service', child: Text('Servico')),
                DropdownMenuItem(value: 'part', child: Text('Peca')),
              ],
              onChanged:
                  (value) => entry.type.value = value ?? entry.type.value,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.nameCtrl,
            decoration: const InputDecoration(labelText: 'Descricao'),
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
                    labelText: 'Valor unitario (R\$)',
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

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.label,
    this.value,
    required this.placeholder,
    this.helperText,
    this.errorText,
    this.onTap,
    this.onClear,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final String placeholder;
  final String? helperText;
  final String? errorText;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final surface = context.themeSurfaceAlt;
    final tileColor = enabled ? surface : surface.withValues(alpha: 0.5);
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    errorText != null
                        ? Theme.of(context).colorScheme.error
                        : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasValue ? value! : placeholder,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              hasValue ? context.themeTextMain : Colors.white54,
                          fontWeight:
                              hasValue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasValue && onClear != null)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 18),
                    splashRadius: 20,
                  )
                else
                  Icon(
                    enabled ? Icons.search : Icons.block,
                    color: enabled ? Colors.white70 : Colors.white30,
                  ),
              ],
            ),
          ),
        ),
        if (helperText != null && helperText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              helperText!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _SinglePickerModal {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String? initialId,
    required String Function(T) id,
    required String Function(T) titleBuilder,
    String Function(T)? subtitleBuilder,
  }) async {
    if (items.isEmpty) return null;
    var query = '';
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.75;
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final lowerQuery = query.toLowerCase();
              final filtered =
                  lowerQuery.isEmpty
                      ? items
                      : items.where((item) {
                        final titleText =
                            titleBuilder(item).toLowerCase().trim();
                        final subtitleText =
                            (subtitleBuilder?.call(item) ?? '')
                                .toLowerCase()
                                .trim();
                        return titleText.contains(lowerQuery) ||
                            subtitleText.contains(lowerQuery);
                      }).toList();

              return SizedBox(
                height: maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModalHeader(title: title),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged:
                            (value) => setState(() => query = value.trim()),
                      ),
                    ),
                    if (filtered.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Nenhum resultado encontrado.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final item = filtered[index];
                            final itemId = id(item);
                            final subtitle = subtitleBuilder?.call(item);
                            return ListTile(
                              onTap: () => Navigator.of(ctx).pop(item),
                              title: Text(titleBuilder(item)),
                              subtitle:
                                  (subtitle != null &&
                                          subtitle.trim().isNotEmpty)
                                      ? Text(subtitle.trim())
                                      : null,
                              trailing:
                                  itemId == initialId
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white70,
                                      )
                                      : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TechnicianPickerModal {
  static Future<List<String>?> show({
    required BuildContext context,
    required List<CollaboratorModel> technicians,
    required List<String> initialSelection,
  }) async {
    if (technicians.isEmpty) return null;
    final selected = initialSelection.toSet();
    var query = '';
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.8;
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              final lowerQuery = query.toLowerCase();
              final filtered =
                  lowerQuery.isEmpty
                      ? technicians
                      : technicians.where((tech) {
                        final name = tech.name.toLowerCase();
                        final email = tech.email.toLowerCase();
                        return name.contains(lowerQuery) ||
                            email.contains(lowerQuery);
                      }).toList();

              return SizedBox(
                height: maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ModalHeader(title: 'Selecionar tecnicos'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged:
                            (value) => setState(() => query = value.trim()),
                      ),
                    ),
                    if (filtered.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Nenhum tecnico encontrado.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) {
                            final tech = filtered[index];
                            final checked = selected.contains(tech.id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (_) {
                                setState(() {
                                  if (checked) {
                                    selected.remove(tech.id);
                                  } else {
                                    selected.add(tech.id);
                                  }
                                });
                              },
                              title: Text(tech.name),
                              subtitle: Text(tech.email),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed:
                                selected.isEmpty
                                    ? null
                                    : () => setState(selected.clear),
                            child: const Text('Limpar'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed:
                                () => Navigator.of(ctx).pop(selected.toList()),
                            child: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _locationDescription(LocationModel model) {
  final parts = <String>[];
  if (model.label.trim().isNotEmpty) parts.add(model.label.trim());
  if (model.addressLine.isNotEmpty) parts.add(model.addressLine);
  if (model.cityState.isNotEmpty) parts.add(model.cityState);
  if (parts.isEmpty) return 'Local ${model.id}';
  return parts.join(' - ');
}

String _equipmentDescription(EquipmentModel equipment) {
  final parts = <String>[];
  if ((equipment.room ?? '').trim().isNotEmpty) {
    parts.add(equipment.room!.trim());
  }
  if ((equipment.brand ?? '').trim().isNotEmpty) {
    parts.add(equipment.brand!.trim());
  }
  if ((equipment.model ?? '').trim().isNotEmpty) {
    parts.add(equipment.model!.trim());
  }
  if ((equipment.type ?? '').trim().isNotEmpty) {
    parts.add(equipment.type!.trim());
  }
  if (parts.isEmpty) return 'Equipamento ${equipment.id}';
  return parts.join(' - ');
}

String _inventoryValue(InventoryItemModel item) {
  final summary = _inventorySummary(item);
  if (summary.isEmpty) return item.name;
  return '${item.name} - $summary';
}

String _inventorySummary(InventoryItemModel item) {
  final parts = <String>[];
  if (item.sku.isNotEmpty) parts.add('SKU ${item.sku}');
  parts.add('Saldo ${item.onHand.toStringAsFixed(2)} ${item.unit}');
  return parts.join(' | ');
}

void _syncFormFieldValue(FormFieldState<String> state, String? value) {
  if (state.value == value) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (state.mounted) {
      state.didChange(value);
    }
  });
}
