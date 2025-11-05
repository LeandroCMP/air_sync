import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import './inventory_item_history_controller.dart';

class InventoryItemHistoryPage extends GetView<InventoryItemHistoryController> {
  const InventoryItemHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Histórico do item',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Obx(() {
        final inventoryItem = controller.item.value;
        final movements = controller.filteredMovements;
        final isLoading = controller.isLoading.value;

        final children = <Widget>[];

        children
          ..add(const SizedBox(height: 16))
          ..add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ItemHeaderCard(item: inventoryItem),
            ),
          )
          ..add(const SizedBox(height: 16))
          ..add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _HistoryFilterBar(controller: controller),
            ),
          )
          ..add(const SizedBox(height: 16));

        if (isLoading && movements.isEmpty) {
          children.add(
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (movements.isEmpty) {
          children.add(
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(
                child: Text(
                  'Nenhuma movimentação registrada para este item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          );
        } else {
          for (var i = 0; i < movements.length; i++) {
            final movement = movements[i];
            children
              ..add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MovementTile(
                    movement: movement,
                    controller: controller,
                    unit: inventoryItem?.unit ?? '',
                  ),
                ),
              )
              ..add(const SizedBox(height: 12));
          }
          if (children.isNotEmpty) {
            children.removeLast();
            children.add(const SizedBox(height: 12));
          }
        }

        return RefreshIndicator(
          color: context.themePrimary,
          backgroundColor: context.themeSurface,
          onRefresh: () => controller.refreshData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: children,
          ),
        );
      }),
    );
  }
}

class _ItemHeaderCard extends StatelessWidget {
  final InventoryItemModel? item;

  const _ItemHeaderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
        ),
        child: const Center(
          child: Text(
            'Carregando informações do item...',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final inventoryItem = item!;
    final formatter = NumberFormat('#,##0.###', 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: context.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inventoryItem.description.isEmpty
                ? 'Item sem descrição'
                : inventoryItem.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'SKU: ${inventoryItem.sku}',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.inventory_2_outlined,
                label: 'Estoque atual',
                value:
                    '${formatter.format(inventoryItem.quantity)} ${inventoryItem.unit}',
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.warning_amber_outlined,
                label: 'Mínimo',
                value:
                    '${formatter.format(inventoryItem.minQuantity)} ${inventoryItem.unit}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  final InventoryItemHistoryController controller;

  const _HistoryFilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.selectedFilter.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            InventoryHistoryFilter.values.map((filter) {
              return ChoiceChip(
                label: Text(_labelForFilter(filter)),
                selected: current == filter,
                onSelected: (_) => controller.changeFilter(filter),
                selectedColor: context.themePrimary,
                labelStyle: TextStyle(
                  color: current == filter ? Colors.white : Colors.white70,
                  fontWeight:
                      current == filter ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: context.themeSurface,
              );
            }).toList(),
      );
    });
  }

  String _labelForFilter(InventoryHistoryFilter filter) {
    switch (filter) {
      case InventoryHistoryFilter.all:
        return 'Todas';
      case InventoryHistoryFilter.entries:
        return 'Entradas';
      case InventoryHistoryFilter.exits:
        return 'Saídas';
      case InventoryHistoryFilter.adjustments:
        return 'Ajustes';
    }
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovementModel movement;
  final InventoryItemHistoryController controller;
  final String unit;

  const _MovementTile({
    required this.movement,
    required this.controller,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isEntry = controller.isEntry(movement.type);
    final isExit = controller.isExit(movement.type);
    final color =
        isEntry
            ? const Color(0xFF4CAF50)
            : isExit
            ? const Color(0xFFE57373)
            : context.themeWarning;
    final icon =
        isEntry
            ? Icons.arrow_downward_rounded
            : isExit
            ? Icons.arrow_upward_rounded
            : Icons.compare_arrows_rounded;

    final qtyText =
        '${isEntry ? '+' : '-'}${controller.formatQuantity(movement.quantity)} ${unit.toUpperCase()}';
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(movement.createdAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          controller.titleForMovement(movement),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.subtitleForMovement(movement),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          qtyText,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.themeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
