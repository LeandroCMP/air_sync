import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/modules/fleet/fleet_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FleetHistoryPage extends GetView<FleetHistoryController> {
  const FleetHistoryPage({super.key});

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Hist?rico - ',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final events = controller.events;
          final summaryEntries = _buildSummaryEntries(events);
          final costTrend = _buildCostTrendEntries(events);
          final hasLoaded = controller.hasLoaded.value;
          final isInitialLoading = controller.isLoading.value && !hasLoaded;
          if (!hasLoaded && isInitialLoading) {
            return const LinearProgressIndicator(minHeight: 2);
          }

          return RefreshIndicator(
            color: context.themePrimary,
            backgroundColor: context.themeSurface,
            onRefresh: controller.refreshData,
            child: CustomScrollView(
              controller: controller.scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _VehicleHeaderCard(
                      title: controller.vehicleTitle,
                      year: controller.yearFilter.value,
                      month: controller.monthFilter.value,
                    ),
                  ),
                ),
                if (summaryEntries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _HistorySummaryRow(entries: summaryEntries),
                    ),
                  ),
                if (costTrend.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _HistoryCostChart(entries: costTrend),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _HistoryTypeFilters(
                      controller: controller,
                      selectedTypes: controller.selectedTypes.toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _HistoryDateFilters(
                      controller: controller,
                      selectedYear: controller.yearFilter.value,
                      selectedMonth: controller.monthFilter.value,
                    ),
                  ),
                ),
                if (controller.isLoading.value && events.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (events.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _HistoryEmptyState(
                      hasFiltersApplied:
                          controller.monthFilter.value != null ||
                          controller.selectedTypes.length != 3,
                      onClearFilters: controller.resetFilters,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = events[index];
                      final date = _extractDate(event);
                      final showHeader = _shouldShowHeader(events, index);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          showHeader ? 12 : 0,
                          20,
                          index == events.length - 1 ? 120 : 12,
                        ),
                        child: _FleetEventTile(
                          event: event,
                          date: date,
                          showHeader: showHeader,
                        ),
                      );
                    }, childCount: events.length),
                  ),
                if (controller.isPaginating.value)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _VehicleHeaderCard extends StatelessWidget {
  const _VehicleHeaderCard({
    required this.title,
    required this.year,
    required this.month,
  });

  final String title;
  final int year;
  final int? month;

  @override
  Widget build(BuildContext context) {
    final monthLabel = month == null ? 'Ano inteiro' : _monthLabel(month!);
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: context.themePrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visualizando $monthLabel / $year',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTypeFilters extends StatelessWidget {
  const _HistoryTypeFilters({
    required this.controller,
    required this.selectedTypes,
  });

  final FleetHistoryController controller;
  final List<String> selectedTypes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipos',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Check',
              icon: Icons.check_circle_outline,
              selected: selectedTypes.contains('check'),
              onTap: () => controller.toggleType('check'),
            ),
            _FilterChip(
              label: 'Abastecimento',
              icon: Icons.local_gas_station,
              selected: selectedTypes.contains('fuel'),
              onTap: () => controller.toggleType('fuel'),
            ),
            _FilterChip(
              label: 'Manutenção',
              icon: Icons.build_circle_outlined,
              selected: selectedTypes.contains('maintenance'),
              onTap: () => controller.toggleType('maintenance'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryDateFilters extends StatelessWidget {
  const _HistoryDateFilters({
    required this.controller,
    required this.selectedYear,
    required this.selectedMonth,
  });

  final FleetHistoryController controller;
  final int selectedYear;
  final int? selectedMonth;

  @override
  Widget build(BuildContext context) {
    final years = controller.availableYears;
    final months = [null, ...List<int>.generate(12, (index) => index + 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DropdownBox<int>(
                label: 'Ano',
                value: selectedYear,
                items: years,
                itemLabelBuilder: (value) => value.toString(),
                onChanged: (value) {
                  if (value != null) controller.setYear(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownBox<int?>(
                label: 'Mês',
                value: selectedMonth,
                items: months,
                itemLabelBuilder: (value) =>
                    value == null ? 'Ano inteiro' : _monthLabel(value),
                onChanged: controller.setMonth,
              ),
            ),
            IconButton(
              tooltip: 'Limpar filtros',
              onPressed: controller.resetFilters,
              icon: const Icon(Icons.filter_alt_off, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistorySummaryRow extends StatelessWidget {
  const _HistorySummaryRow({required this.entries});

  final List<_HistorySummaryInfo> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final children = List.generate(entries.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              right: isWide && index != entries.length - 1 ? 12 : 0,
              bottom: isWide ? 0 : (index == entries.length - 1 ? 0 : 12),
            ),
            child: SizedBox(
              width: isWide ? null : double.infinity,
              child: _HistorySummaryCard(info: entries[index]),
            ),
          );
        });
        return isWide ? Row(children: children.map((c) => Expanded(child: c)).toList()) : Column(children: children);
      },
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({required this.info});

  final _HistorySummaryInfo info;

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
          Row(
            children: [
              Icon(info.icon, color: info.color, size: 20),
              const SizedBox(width: 8),
              Text(info.label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCostChart extends StatelessWidget {
  const _HistoryCostChart({required this.entries});

  final List<_CostTrendEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custo acumulado',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _CostTrendPainter(entries: entries),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySummaryInfo {
  const _HistorySummaryInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _CostTrendEntry {
  const _CostTrendEntry({required this.at, required this.value});

  final DateTime at;
  final double value;
}

class _FleetEventTile extends StatelessWidget {
  const _FleetEventTile({
    required this.event,
    required this.date,
    required this.showHeader,
  });

  final Map<String, dynamic> event;
  final DateTime? date;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final type = _eventType(event);
    final title = _titleFor(type);
    final subtitle = _subtitleFor(event);
    final chips = _detailChips(event);
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader && date != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                DateFormat('EEEE, dd MMMM', 'pt_BR').format(date!),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _colorFor(type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconFor(type), color: _colorFor(type)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      date != null
                          ? FleetHistoryPage._dateTimeFormat.format(date!)
                          : 'Data não informada',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.hasFiltersApplied,
    required this.onClearFilters,
  });

  final bool hasFiltersApplied;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final title = hasFiltersApplied
        ? 'Sem eventos para os filtros selecionados'
        : 'Nenhum evento registrado ainda';
    final subtitle = hasFiltersApplied
        ? 'Ajuste os filtros ou limpe-os para ver todos os registros.'
        : 'Registre abastecimentos, manutenções ou checks para começar.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, color: Colors.white54, size: 64),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (hasFiltersApplied) ...[
            const SizedBox(height: 16),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: context.themeSurface,
      ),
      dropdownColor: context.themeSurface,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

DateTime? _extractDate(Map<String, dynamic> event) {
  final raw =
      event['at'] ?? event['createdAt'] ?? event['date'] ?? event['timestamp'];
  if (raw is String) return DateTime.tryParse(raw)?.toLocal();
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
  return null;
}

bool _shouldShowHeader(List<Map<String, dynamic>> events, int index) {
  final currentDate = _extractDate(events[index]);
  if (currentDate == null) return false;
  if (index == 0) return true;
  final prevDate = _extractDate(events[index - 1]);
  if (prevDate == null) return true;
  return DateTime(currentDate.year, currentDate.month, currentDate.day) !=
      DateTime(prevDate.year, prevDate.month, prevDate.day);
}

String _eventType(Map<String, dynamic> event) {
  return (event['type'] ?? event['eventType'] ?? '').toString().toLowerCase();
}

String _titleFor(String type) {
  switch (type) {
    case 'fuel':
      return 'Abastecimento';
    case 'maintenance':
      return 'Manutenção';
    case 'check':
      return 'Check';
    default:
      return 'Evento';
  }
}

String _subtitleFor(Map<String, dynamic> event) {
  final buffer = StringBuffer();
  final odo = event['km'] ?? event['atKm'] ?? event['odometer'] ?? event['odo'];
  if (odo != null && odo.toString().isNotEmpty) {
    buffer.write('Odômetro:  km');
  }
  final notes = (event['notes'] ?? event['description'])?.toString();
  if (notes != null && notes.trim().isNotEmpty) {
    if (buffer.isNotEmpty) buffer.write(' • ');
    buffer.write(notes.trim());
  }
  return buffer.toString();
}

List<Widget> _detailChips(Map<String, dynamic> event) {
  final type = _eventType(event);
  final chips = <Widget>[];
  final fuelLevel = event['fuelLevel'];
  final liters = event['liters'] ?? event['qty'];
  final cost = event['cost'] ?? event['price'] ?? event['total'];
  final fuelType = event['fuelType'];

  if (type == 'check' && fuelLevel != null) {
    chips.add(_DetailChip(label: 'Combustível', value: '%'));
  }
  if (type == 'fuel') {
    if (liters != null) {
      chips.add(_DetailChip(label: 'Litros', value: liters.toString()));
    }
    if (fuelType != null && fuelType.toString().isNotEmpty) {
      chips.add(_DetailChip(label: 'Tipo', value: fuelType.toString()));
    }
  }
  final costValue = _asDouble(cost);
  if (costValue != null && costValue > 0) {
    chips.add(
      _DetailChip(
        label: 'Custo',
        value: FleetHistoryPage._currencyFormat.format(costValue),
      ),
    );
  }
  final performedBy = event['performedBy'] ?? event['user'] ?? event['author'];
  if ((performedBy ?? '').toString().trim().isNotEmpty) {
    chips.add(
      _DetailChip(label: 'Responsável', value: performedBy.toString()),
    );
  }
  return chips;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

List<_HistorySummaryInfo> _buildSummaryEntries(
  List<Map<String, dynamic>> events,
) {
  if (events.isEmpty) return const [];
  final total = events.length;
  final fuelCount = events.where((e) => _eventType(e) == 'fuel').length;
  final maintenanceCount =
      events.where((e) => _eventType(e) == 'maintenance').length;
  final totalCost = events.fold<double>(0, (sum, event) {
    final cost = _asDouble(event['cost'] ?? event['price'] ?? event['total']);
    return sum + (cost ?? 0);
  });

  return [
    _HistorySummaryInfo(
      icon: Icons.event_note,
      label: 'Eventos',
      value: total.toString(),
      color: const Color(0xFF90CAF9),
    ),
    _HistorySummaryInfo(
      icon: Icons.local_gas_station,
      label: 'Abastecimentos',
      value: fuelCount.toString(),
      color: const Color(0xFF4CAF50),
    ),
    _HistorySummaryInfo(
      icon: Icons.build_circle_outlined,
      label: 'Manutenções',
      value: maintenanceCount.toString(),
      color: const Color(0xFFF48FB1),
    ),
    _HistorySummaryInfo(
      icon: Icons.attach_money,
      label: 'Custo total',
      value: FleetHistoryPage._currencyFormat.format(totalCost),
      color: const Color(0xFFFFB74D),
    ),
  ];
}

List<_CostTrendEntry> _buildCostTrendEntries(
  List<Map<String, dynamic>> events,
) {
  final filtered = <Map<String, dynamic>>[];
  for (final event in events) {
    final cost = _asDouble(event['cost'] ?? event['price'] ?? event['total']);
    final date = _extractDate(event);
    if (cost != null && cost > 0 && date != null) {
      filtered.add({'date': date, 'cost': cost});
    }
  }
  if (filtered.isEmpty) return const [];
  filtered.sort(
    (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
  );
  double cumulative = 0;
  return filtered
      .map(
        (item) {
          cumulative += item['cost'] as double;
          return _CostTrendEntry(at: item['date'] as DateTime, value: cumulative);
        },
      )
      .toList();
}

String _monthLabel(int month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  if (month < 1 || month > 12) return 'Mês';
  return months[month - 1];
}

Color _colorFor(String type) {
  switch (type) {
    case 'fuel':
      return const Color(0xFF4CAF50);
    case 'maintenance':
      return const Color(0xFFF48FB1);
    case 'check':
      return const Color(0xFF90CAF9);
    default:
      return const Color(0xFFBDBDBD);
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'fuel':
      return Icons.local_gas_station;
    case 'maintenance':
      return Icons.build_circle_outlined;
    case 'check':
      return Icons.check_circle_outline;
    default:
      return Icons.event_note;
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostTrendPainter extends CustomPainter {
  const _CostTrendPainter({required this.entries});

  final List<_CostTrendEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;
    final sorted = List<_CostTrendEntry>.from(entries)
      ..sort((a, b) => a.at.compareTo(b.at));
    final minTime = sorted.first.at.millisecondsSinceEpoch.toDouble();
    final maxTime = sorted.last.at.millisecondsSinceEpoch.toDouble();
    final minValue = sorted.first.value;
    final maxValue = sorted.last.value;
    final dx = size.width - 24;
    final dy = size.height - 24;
    final offsetX = 12.0;
    final offsetY = 12.0;
    final timeRange =
        (maxTime - minTime).abs() < 0.001 ? 1.0 : (maxTime - minTime);
    final valueRange =
        (maxValue - minValue).abs() < 0.001 ? 1.0 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = offsetY + (dy * (i / 3));
      canvas.drawLine(Offset(offsetX, y), Offset(offsetX + dx, y), gridPaint);
    }

    final points = sorted.map((entry) {
      final normalizedTime =
          (entry.at.millisecondsSinceEpoch - minTime) / timeRange;
      final normalizedValue = (entry.value - minValue) / valueRange;
      final x = offsetX + (normalizedTime * dx);
      final y = offsetY + dy - (normalizedValue * dy);
      return Offset(x, y);
    }).toList();

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath
      ..lineTo(points.last.dx, offsetY + dy)
      ..lineTo(points.first.dx, offsetY + dy)
      ..close();
    final fillPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
