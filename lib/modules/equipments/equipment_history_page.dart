import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/maintenance_reminder_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'equipment_history_controller.dart';
import 'widgets/maintenance_history_card.dart';

class EquipmentHistoryPage extends GetView<EquipmentHistoryController> {
  const EquipmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.themeDark,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Historico de manutencao',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              tooltip: 'Relatorio (PDF)',
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Colors.white,
              ),
              onPressed: controller.exportPdf,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historico'),
              Tab(text: 'Proximos lembretes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Obx(
              () => _HistoryTab(
                loading: controller.isLoading.value,
                items: controller.items.toList(),
              ),
            ),
            Obx(
              () => _RemindersTab(
                loading: controller.remindersLoading.value,
                error: controller.remindersError.value,
                reminders: controller.reminders.toList(),
                onReload: controller.loadReminders,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.loading,
    required this.items,
  });

  final bool loading;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Sem registros',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder:
                      (_, index) => MaintenanceHistoryCard(entry: items[index]),
                ),
        ),
      ],
    );
  }
}

class _RemindersTab extends StatelessWidget {
  const _RemindersTab({
    required this.loading,
    required this.error,
    required this.reminders,
    required this.onReload,
  });

  final bool loading;
  final String? error;
  final List<MaintenanceReminderModel> reminders;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (reminders.isEmpty) {
      return const Center(
        child: Text(
          'Sem lembretes pendentes',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.separated(
      itemCount: reminders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _ReminderCard(reminder: reminders[index]),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder});

  final MaintenanceReminderModel reminder;

  @override
  Widget build(BuildContext context) {
    final dueAt = reminder.nextDueAt?.toLocal();
    final now = DateTime.now();
    int? daysDiff;
    if (dueAt != null) {
      daysDiff = dueAt.difference(now).inDays;
    }
    final isOverdue = daysDiff != null && daysDiff < 0;
    final isSoon = daysDiff != null && daysDiff >= 0 && daysDiff <= 7;

    final baseColor = context.themeSurfaceAlt;
    final bgColor = isOverdue
        ? Colors.redAccent.withValues(alpha: 0.15)
        : isSoon
            ? Colors.orangeAccent.withValues(alpha: 0.14)
            : baseColor;
    final borderColor = isOverdue
        ? Colors.redAccent
        : isSoon
            ? Colors.orangeAccent
            : Colors.white12;

    final statusLabel =
        reminder.status.trim().isEmpty ? 'pending' : reminder.status.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reminder.serviceName.isNotEmpty
                ? reminder.serviceName
                : 'Servico',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tipo: ${reminder.serviceTypeCode}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                dueAt != null ? DateFormat('dd/MM/yyyy').format(dueAt) : '--',
                style: TextStyle(
                  color: isOverdue
                      ? Colors.redAccent
                      : isSoon
                          ? Colors.orangeAccent
                          : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (daysDiff != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    isOverdue
                        ? 'Vencido'
                        : daysDiff == 0
                            ? 'Hoje'
                            : daysDiff == 1
                                ? 'Em 1 dia'
                                : 'Em $daysDiff dias',
                    style: TextStyle(
                      color: isOverdue
                          ? Colors.redAccent
                          : Colors.orangeAccent.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Status: $statusLabel',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
