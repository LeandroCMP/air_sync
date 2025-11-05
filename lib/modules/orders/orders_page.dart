import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import './orders_controller.dart';
import 'order_detail_bindings.dart';
import 'order_detail_page.dart';

class OrdersPage extends GetView<OrdersController> {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM • HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: controller.openCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final orders = controller.visibleOrders;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isLoading ? 2 : 0,
              child:
                  isLoading
                      ? const LinearProgressIndicator(minHeight: 2)
                      : const SizedBox.shrink(),
            ),
            _FiltersHeader(controller: controller),
            Expanded(
              child:
                  orders.isEmpty
                      ? _EmptyState(onClear: controller.clearFilters)
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemBuilder: (_, index) {
                          final order = orders[index];
                          return _OrderTile(
                            order: order,
                            subtitle: _subtitleFor(order, dateFmt),
                            onTap: () => _openOrder(order),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: orders.length,
                      ),
            ),
          ],
        );
      }),
    );
  }

  String _subtitleFor(OrderModel order, DateFormat fmt) {
    final segments = <String>[];
    if (order.scheduledAt != null) {
      segments.add(fmt.format(order.scheduledAt!.toLocal()));
    }
    if ((order.locationLabel ?? '').isNotEmpty) {
      segments.add(order.locationLabel!);
    }
    if ((order.equipmentLabel ?? '').isNotEmpty) {
      segments.add(order.equipmentLabel!);
    }
    if (order.notes != null && order.notes!.trim().isNotEmpty) {
      segments.add(order.notes!.trim());
    }
    return segments.join(' • ');
  }

  void _openOrder(OrderModel order) {
    Get.to<OrderModel?>(
      () => const OrderDetailPage(),
      binding: OrderDetailBindings(orderId: order.id),
      arguments: order,
    );
  }
}

class _FiltersHeader extends StatelessWidget {
  const _FiltersHeader({required this.controller});

  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          Obx(() {
            final currentStatus = controller.status.value;
            final meta = _statusFor(currentStatus);
            return Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterChip(
                  label: 'Hoje',
                  selected: controller.period.value == 'today',
                  onTap: () => controller.period.value = 'today',
                ),
                _FilterChip(
                  label: 'Semana',
                  selected: controller.period.value == 'week',
                  onTap: () => controller.period.value = 'week',
                ),
                _FilterChip(
                  label: 'Mês',
                  selected: controller.period.value == 'month',
                  onTap: () => controller.period.value = 'month',
                ),
                InputChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: meta.color),
                      const SizedBox(width: 8),
                      Text(
                        currentStatus.isEmpty ? 'Status' : meta.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  labelStyle: const TextStyle(color: Colors.white),
                  backgroundColor:
                      currentStatus.isEmpty
                          ? context.themeGray
                          : meta.color.withOpacity(.15),
                  side:
                      currentStatus.isEmpty
                          ? BorderSide.none
                          : BorderSide(color: meta.color),
                  onPressed: () => _openStatusSheet(context),
                  onDeleted:
                      currentStatus.isEmpty
                          ? null
                          : () => controller.status.value = '',
                  deleteIcon:
                      currentStatus.isEmpty
                          ? null
                          : Icon(Icons.clear, size: 18, color: meta.color),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          _SearchField(onChanged: controller.setSearch),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Obx(() {
              final count = controller.visibleOrders.length;
              final text = count == 0 ? 'Nenhuma OS encontrada' : '$count OS';
              return Text(
                text,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _openStatusSheet(BuildContext context) {
    final current = controller.status.value;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Filtrar por status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final item in _statusOptions)
                  ListTile(
                    leading: Icon(item.icon, color: item.color),
                    title: Text(
                      item.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing:
                        current == item.value
                            ? Icon(Icons.check, color: item.color)
                            : null,
                    onTap: () {
                      controller.status.value = item.value;
                      Get.back();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.white70),
                  title: const Text(
                    'Todos',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    controller.status.value = '';
                    Get.back();
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.subtitle,
    required this.onTap,
  });

  final OrderModel order;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _statusFor(order.status);
    return Material(
      color: context.themeDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: meta.color.withOpacity(.15),
                foregroundColor: meta.color,
                child: Icon(meta.icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.clientName ?? 'Cliente não informado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: context.themeGreen.withOpacity(.2),
      backgroundColor: context.themeDark,
      labelStyle: TextStyle(
        color: selected ? context.themeGreen : Colors.white,
      ),
      side:
          selected
              ? BorderSide(color: context.themeGreen)
              : const BorderSide(color: Colors.white24),
      onSelected: (_) => onTap(),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar por cliente, local ou equipamento...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: Theme.of(context).cardColor.withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
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
  const _EmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Colors.white38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sem ordens no período selecionado',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajuste os filtros ou utilize a busca para localizar outra OS.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onClear, child: const Text('Limpar filtros')),
          ],
        ),
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;
}

_StatusItem _statusFor(String value) {
  if (value.isEmpty) {
    return const _StatusItem(
      value: '',
      label: 'Status',
      color: Colors.white54,
      icon: Icons.filter_list,
    );
  }
  return _statusOptions.firstWhere(
    (item) => item.value == value,
    orElse:
        () => const _StatusItem(
          value: '',
          label: 'Status',
          color: Colors.white54,
          icon: Icons.filter_list,
        ),
  );
}

const List<_StatusItem> _statusOptions = [
  _StatusItem(
    value: 'scheduled',
    label: 'Agendada',
    color: Colors.blueAccent,
    icon: Icons.event_available,
  ),
  _StatusItem(
    value: 'in_progress',
    label: 'Em andamento',
    color: Colors.orange,
    icon: Icons.build,
  ),
  _StatusItem(
    value: 'done',
    label: 'Concluída',
    color: Colors.green,
    icon: Icons.check_circle,
  ),
  _StatusItem(
    value: 'canceled',
    label: 'Cancelada',
    color: Colors.redAccent,
    icon: Icons.cancel,
  ),
];
