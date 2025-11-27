import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/modules/inventory/widgets/cost_history_chart.dart';
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
      body: SafeArea(
        child: Obx(() {
          final item = controller.item.value;
          final movements = controller.filteredMovements;
          final isLoading = controller.isLoading.value;
          final summaryEntries = _buildSummaryEntries(controller);

          return RefreshIndicator(
            color: context.themePrimary,
            backgroundColor: context.themeSurface,
            onRefresh: controller.refreshData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _ItemHeaderCard(item: item),
                  ),
                ),
                if (summaryEntries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _HistorySummaryRow(entries: summaryEntries),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _MonthFilterBar(controller: controller),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _HistoryFilterBar(controller: controller),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _CostHistorySection(controller: controller),
                  ),
                ),
                if (isLoading && movements.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (movements.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _HistoryEmptyState(
                      hasData: (item?.movements ?? const []).isNotEmpty,
                      onClearFilters: () {
                        controller.changeFilter(InventoryHistoryFilter.all);
                        controller.setMonthFilter(null);
                      },
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final movement = movements[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          index == movements.length - 1 ? 120 : 12,
                        ),
                        child: _MovementTile(
                          movement: movement,
                          controller: controller,
                          unit: item?.unit ?? '',
                        ),
                      );
                    }, childCount: movements.length),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

List<_HistorySummaryInfo> _buildSummaryEntries(
  InventoryItemHistoryController controller,
) {
  final year = controller.yearFilter.value;
  final month = controller.monthFilter.value;
  final subset =
      controller.movements.where((movement) {
        final date = movement.createdAt.toLocal();
        if (date.year != year) return false;
        if (month != null && date.month != month) return false;
        return true;
      }).toList();
  if (subset.isEmpty) return const [];

  final entries = subset.where((m) => controller.isEntry(m.type)).length;
  final exits = subset.where((m) => controller.isExit(m.type)).length;
  final adjustments =
      subset.where((m) => controller.isAdjustment(m.type)).length;
  final total = subset.length;
  final net = subset.fold<double>(0, (sum, movement) {
    if (controller.isEntry(movement.type)) return sum + movement.quantity;
    if (controller.isExit(movement.type)) return sum - movement.quantity;
    return movement.type == MovementType.adjustPos
        ? sum + movement.quantity
        : sum - movement.quantity;
  });
  final unit = controller.item.value?.unit ?? '';
  final netLabel =
      net == 0
          ? '0 ${unit.trim().isEmpty ? '' : unit}'
          : '${net > 0 ? '+' : '-'}${controller.formatQuantity(net.abs())}'
                  ' ${unit.trim()}'
              .trim();

  return [
    _HistorySummaryInfo(
      label: 'Movimentos',
      value: total.toString(),
      color: Colors.blueAccent,
      icon: Icons.history,
    ),
    _HistorySummaryInfo(
      label: 'Entradas',
      value: entries.toString(),
      color: Colors.greenAccent,
      icon: Icons.call_received,
    ),
    _HistorySummaryInfo(
      label: 'Saídas',
      value: exits.toString(),
      color: Colors.redAccent,
      icon: Icons.call_made,
    ),
    _HistorySummaryInfo(
      label: 'Ajustes',
      value: adjustments.toString(),
      color: Colors.amberAccent,
      icon: Icons.tune,
    ),
    _HistorySummaryInfo(
      label: 'Saldo',
      value: netLabel,
      color: Colors.tealAccent,
      icon: Icons.balance,
    ),
  ];
}

class _HistorySummaryRow extends StatelessWidget {
  const _HistorySummaryRow({required this.entries});

  final List<_HistorySummaryInfo> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final entry = entries[index];
          return SizedBox(
            width: 150,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: entry.color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      entry.icon,
                      color: Color.lerp(entry.color, Colors.white, 0.3),
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    entry.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistorySummaryInfo {
  const _HistorySummaryInfo({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
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
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              InventoryHistoryFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(_labelForFilter(filter)),
                  selected: current == filter,
                  onSelected: (_) => controller.changeFilter(filter),
                  selectedColor: Color.lerp(
                    context.themePrimary,
                    Colors.white,
                    0.3,
                  ),
                  backgroundColor: context.themeSurface,
                );
              }).toList(),
        ),
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

class _MonthFilterBar extends StatelessWidget {
  const _MonthFilterBar({required this.controller});

  final InventoryItemHistoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final years = controller.availableYears;
      final selectedYear = controller.yearFilter.value;
      final selectedMonth = controller.monthFilter.value;
      final months = controller.monthsForYear(selectedYear);
      final monthFormatter = DateFormat('MMM', 'pt_BR');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Período',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    dropdownColor: context.themeSurface,
                    iconEnabledColor: Colors.white70,
                    items:
                        years
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(
                                  year.toString(),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) controller.setYearFilter(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: selectedMonth == null,
                    onSelected: (_) => controller.setMonthFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...months.map((month) {
                    final chipLabel =
                        monthFormatter
                            .format(DateTime(selectedYear, month))
                            .toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(chipLabel),
                        selected: selectedMonth == month,
                        onSelected: (_) => controller.setMonthFilter(month),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.hasData,
    required this.onClearFilters,
  });

  final bool hasData;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final title =
        hasData
            ? 'Nenhuma movimentação para os filtros selecionados'
            : 'Ainda não há movimentações para este item';
    final subtitle =
        hasData
            ? 'Ajuste os filtros ou limpe-os para visualizar outros registros.'
            : 'As movimentações aparecerão aqui assim que forem registradas.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timeline_outlined, size: 72, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (hasData) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CostHistorySection extends StatelessWidget {
  final InventoryItemHistoryController controller;

  const _CostHistorySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalEntries = controller.costHistory;
    if (totalEntries.isEmpty) {
      return _CostHistoryEmptyCard(
        title: 'Sem histórico de custo',
        subtitle:
            'Os registros de custo aparecerão aqui após as primeiras entradas de compra.',
        showClear: false,
      );
    }

    final filtered = controller.filteredCostHistory;
    if (filtered.isEmpty) {
      return _CostHistoryEmptyCard(
        title: 'Nenhum custo no período selecionado',
        subtitle: 'Ajuste os filtros de mês ou ano para visualizar os valores.',
        onClear: () => controller.setMonthFilter(null),
      );
    }

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final latest = filtered.first;
    final highest = filtered.reduce(
      (value, element) => element.cost > value.cost ? element : value,
    );
    final lowest = filtered.reduce(
      (value, element) => element.cost < value.cost ? element : value,
    );
    double? variationPct;
    if (filtered.length > 1) {
      final previous = filtered[1].cost;
      if (previous != 0) {
        variationPct = ((latest.cost - previous) / previous) * 100;
      }
    }
    final preview = filtered.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Histórico de custo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (variationPct != null)
                Chip(
                  backgroundColor:
                      variationPct >= 0
                          ? Colors.redAccent.withValues(alpha: 0.25)
                          : Colors.greenAccent.withValues(alpha: 0.18),
                  label: Text(
                    variationPct >= 0
                        ? '+${variationPct.toStringAsFixed(1)}% vs. registro anterior'
                        : '${variationPct.toStringAsFixed(1)}% vs. registro anterior',
                  ),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InventoryCostHistoryChart(
            entries: filtered,
            lineColor: context.themePrimary,
            fillColor: context.themePrimary.withValues(alpha: 0.18),
            gridColor: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.attach_money_outlined,
                  label: 'Último custo',
                  value: currency.format(latest.cost),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.trending_up_outlined,
                  label: 'Maior custo',
                  value: currency.format(highest.cost),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.trending_down_outlined,
                  label: 'Menor custo',
                  value: currency.format(lowest.cost),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, index) => _CostHistoryTile(entry: preview[index]),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: preview.length,
          ),
          if (filtered.length > preview.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Mostrando ${preview.length} de ${filtered.length} registros.',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _CostHistoryTile extends StatelessWidget {
  final InventoryCostHistoryEntry entry;

  const _CostHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy HH:mm').format(entry.at.toLocal());
    final source = entry.source?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.themeDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.price_change_outlined, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency.format(entry.cost),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: Colors.white54)),
                if (source != null && source.isNotEmpty)
                  Text(
                    source,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CostHistoryEmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showClear;
  final VoidCallback? onClear;

  const _CostHistoryEmptyCard({
    required this.title,
    required this.subtitle,
    this.onClear,
    this.showClear = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          if (showClear && onClear != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ),
        ],
      ),
    );
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
          backgroundColor: color.withValues(alpha: 0.15),
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
