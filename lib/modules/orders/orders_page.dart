import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import './orders_controller.dart';
import 'order_detail_page.dart';
import 'order_detail_controller.dart';

class OrdersPage extends GetView<OrdersController> {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM • HH:mm'); // fallback
    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      body: Obx(() {
        final isLoading = controller.isLoading.value;

        return Column(
          children: [
            // linha de progresso sutil
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isLoading ? 2 : 0,
              child: isLoading
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox.shrink(),
            ),

            // ===== Header (não-pinned) com Wrap: chips + status + busca =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  // Wrap quebra para a próxima linha quando faltar espaço
                  Obx(() {
                    final status = controller.status.value;
                    final statusMeta = _statusChipMeta(status);

                    return Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _FilterChip(
                          label: 'Hoje',
                          selected: controller.period.value == 'today',
                          onTap: () {
                            controller.period.value = 'today';
                          },
                        ),
                        _FilterChip(
                          label: 'Semana',
                          selected: controller.period.value == 'week',
                          onTap: () {
                            controller.period.value = 'week';
                          },
                        ),
                        _FilterChip(
                          label: 'Mês',
                          selected: controller.period.value == 'month',
                          onTap: () {
                            controller.period.value = 'month';
                          },
                        ),

                        // Chip de Status (abre bottom sheet)
                        InputChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,
                                  size: 10, color: statusMeta.color),
                              const SizedBox(width: 8),
                              Text(
                                status.isEmpty
                                    ? 'Status'
                                    : statusMeta.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          labelStyle: const TextStyle(color: Colors.white),
                          backgroundColor:
                              status.isEmpty ? context.themeGray : statusMeta.color.withOpacity(.15),
                          side: status.isEmpty
                              ? BorderSide.none
                              : BorderSide(color: statusMeta.color),
                          onPressed: () => _openStatusSheet(context),
                          onDeleted: status.isEmpty
                              ? null
                              : () => controller.status.value = '',
                          deleteIcon: status.isEmpty
                              ? null
                              : Icon(Icons.clear, size: 18, color: statusMeta.color),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 10),

                  // Busca (100% largura)
                  _SearchField(onChanged: controller.setSearch),

                  const SizedBox(height: 6),

                  // Contador (sempre com espaço reservado)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Obx(() {
                      final count = controller.visibleOrders.length;
                      return Opacity(
                        opacity: count == 0 ? 0 : 1,
                        child: Text(
                          '$count ordem${count == 1 ? '' : 's'} encontrada${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ===== Lista / Empty =====
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshList,
                child: Obx(() {
                  final items = controller.visibleOrders;

                  if (controller.isLoading.value) {
                    // mantém área rolável para o pull-to-refresh
                    return  ListView(
                      children: [
                        SizedBox(height: 200),
                        Center(child: CircularProgressIndicator()),
                        SizedBox(height: 400),
                      ],
                    );
                  }

                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 24),
                        _EmptyState(onClear: controller.clearFilters),
                        const SizedBox(height: 200),
                      ],
                    );
                  }

                  final sections = _groupOrdersByDay(items);
                  return ListView.separated(
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final section = sections[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DayHeader(day: section.day),
                          ...section.items.map(
                            (o) => _OrderTile(order: o, format: dateFmt),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ======= Bottom sheet do Status =======
  void _openStatusSheet(BuildContext context) {
    final items = const [
      _StatusItem(value: 'scheduled', label: 'Agendadas', color: Colors.blueAccent),
      _StatusItem(value: 'in_progress', label: 'Em andamento', color: Colors.orange),
      _StatusItem(value: 'finished', label: 'Concluídas', color: Colors.green),
      _StatusItem(value: 'canceled', label: 'Canceladas', color: Colors.redAccent),
    ];

    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const ListTile(
                title: Text('Filtrar por status',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              for (final it in items)
                ListTile(
                  leading: Icon(Icons.circle, size: 12, color: it.color),
                  title: Text(it.label),
                  onTap: () {
                    controller.status.value = it.value;
                    Get.back();
                  },
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  controller.status.value = '';
                  Get.back();
                },
                child: const Text('Limpar status'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/* ===========================
 * Agrupamento por dia
 * =========================== */

class _DaySection {
  final DateTime day; // Y/M/D
  final List<OrderModel> items;
  _DaySection({required this.day, required this.items});
}

List<_DaySection> _groupOrdersByDay(List<OrderModel> list) {
  final map = <DateTime, List<OrderModel>>{};
  for (final o in list) {
    final d = o.scheduledAt;
    final key = (d != null)
        ? DateTime(d.year, d.month, d.day)
        : DateTime(1900, 1, 1); // "sem data"
    map.putIfAbsent(key, () => []).add(o);
  }

  final keys = map.keys.toList()..sort((a, b) => a.compareTo(b));

  final sections = <_DaySection>[];
  for (final k in keys) {
    sections.add(_DaySection(day: k, items: map[k]!));
  }
  return sections;
}

String _dayHeaderLabel(DateTime day) {
  if (day.year == 1900) return 'Sem data';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';
  return DateFormat('dd/MM').format(day);
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        _dayHeaderLabel(day),
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

/* ===========================
 * Tile de Ordem
 * =========================== */

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  final DateFormat format;
  const _OrderTile({required this.order, required this.format});

  @override
  Widget build(BuildContext context) {
    final statusMeta = _statusMeta(order.status);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusMeta.color.withOpacity(0.2),
        child: Icon(statusMeta.icon, color: statusMeta.color),
      ),
      title: Text(order.clientName, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        [
          if (order.scheduledAt != null) _friendlyDate(order.scheduledAt!),
          if (order.location != null) order.location!,
          if (order.equipment != null) order.equipment!,
        ].join(' • '),
        style: const TextStyle(color: Colors.white70),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusMeta.color.withOpacity(0.15),
          border: Border.all(color: statusMeta.color),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          statusMeta.label,
          style: TextStyle(
            color: statusMeta.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () {
        Get.to(
          () => const OrderDetailPage(),
          arguments: order,
          binding: BindingsBuilder(() {
            Get.put(OrderDetailController(service: Get.find()));
          }),
        );
      },
    );
  }

  String _friendlyDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final theDay = DateTime(local.year, local.month, local.day);
    final diff = theDay.difference(today).inDays;
    final hm = DateFormat.Hm().format(local);

    if (diff == 0) return 'Hoje às $hm';
    if (diff == 1) return 'Amanhã às $hm';
    if (diff == -1) return 'Ontem às $hm';
    return DateFormat('dd/MM • HH:mm').format(local);
  }

  _StatusMeta _statusMeta(String s) {
    switch (s) {
      case 'scheduled':
        return _StatusMeta('Agendada', Colors.blueAccent, Icons.event_available);
      case 'in_progress':
        return _StatusMeta('Em andamento', Colors.orange, Icons.build);
      case 'finished':
        return _StatusMeta('Concluída', Colors.green, Icons.check_circle);
      case 'canceled':
        return _StatusMeta('Cancelada', Colors.redAccent, Icons.cancel);
      default:
        return _StatusMeta('Indefinido', Colors.grey, Icons.help_outline);
    }
  }
}

/* ===========================
 * Widgets auxiliares
 * =========================== */

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.themeGreen : context.themeGray,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.calendar_today, size: 12, color: Colors.black87),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? context.themeGray : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar cliente, local ou equipamento...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: Theme.of(context).cardColor.withOpacity(0.25),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeGreen, width: 1.2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.event_note_outlined,
                size: 56, color: Colors.white38),
            const SizedBox(height: 12),
            const Text(
              'Sem ordens no período selecionado',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Tente alterar o período, o status ou use a busca acima.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onClear,
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================
 * Tipos/cores de status
 * =========================== */

class _StatusItem {
  final String value;
  final String label;
  final Color color;
  const _StatusItem({
    required this.value,
    required this.label,
    required this.color,
  });
}

_StatusItem _statusChipMeta(String s) {
  switch (s) {
    case 'scheduled':
      return const _StatusItem(
          value: 'scheduled', label: 'Agendadas', color: Colors.blueAccent);
    case 'in_progress':
      return const _StatusItem(
          value: 'in_progress', label: 'Em andamento', color: Colors.orange);
    case 'finished':
      return const _StatusItem(
          value: 'finished', label: 'Concluídas', color: Colors.green);
    case 'canceled':
      return const _StatusItem(
          value: 'canceled', label: 'Canceladas', color: Colors.redAccent);
    default:
      return const _StatusItem(
          value: '', label: 'Status', color: Colors.white54);
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  final IconData icon;
  _StatusMeta(this.label, this.color, this.icon);
}

_StatusMeta _statusMeta(String s) {
  switch (s) {
    case 'scheduled':
      return _StatusMeta('Agendada', Colors.blueAccent, Icons.event_available);
    case 'in_progress':
      return _StatusMeta('Em andamento', Colors.orange, Icons.build);
    case 'finished':
      return _StatusMeta('Concluída', Colors.green, Icons.check_circle);
    case 'canceled':
      return _StatusMeta('Cancelada', Colors.redAccent, Icons.cancel);
    default:
      return _StatusMeta('Indefinido', Colors.grey, Icons.help_outline);
  }
}
