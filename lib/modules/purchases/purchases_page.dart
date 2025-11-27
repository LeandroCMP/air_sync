import 'dart:async';

import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/models/cost_center_model.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'purchases_controller.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/modules/inventory/inventory_page.dart';
import 'package:intl/intl.dart';
import 'models/purchase_prefill.dart';

final NumberFormat _purchaseCurrencyFormatter =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final DateFormat _purchaseDateFormatter = DateFormat('dd/MM/yyyy');
final DateFormat _purchaseMonthFormatter = DateFormat.MMM('pt_BR');
final DateFormat _purchaseMonthYearFormatter = DateFormat('MMM yyyy', 'pt_BR');

String _formatSupplierDocument(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }
  if (digits.length == 14) {
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }
  return value?.trim() ?? '';
}

String _formatSupplierPhone(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return value?.trim() ?? '';
}

List<String> _supplierContactParts(
  SupplierModel? supplier, {
  bool includeLabels = false,
}) {
  if (supplier == null) return const [];
  final parts = <String>[];
  final doc = _formatSupplierDocument(supplier.docNumber);
  if (doc.isNotEmpty) {
    parts.add(includeLabels ? 'Doc.: $doc' : doc);
  }
  final phone = _formatSupplierPhone(supplier.phone);
  if (phone.isNotEmpty) {
    parts.add(includeLabels ? 'Tel.: $phone' : phone);
  }
  final email = (supplier.email ?? '').trim();
  if (email.isNotEmpty) {
    parts.add(email);
  }
  return parts;
}

double? _parseCurrencyText(String? text) {
  final digits = text?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
  if (digits.isEmpty) return null;
  final value = double.tryParse(digits);
  if (value == null) return null;
  return value / 100;
}

class PurchasesPage extends GetView<PurchasesController> {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = controller.consumePrefillDraft();
      if (draft != null) {
        _openCreateBottomSheet(context, prefill: draft);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Compras', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openCreateBottomSheet(context),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: SafeArea(

        child: Obx(() {

          final isLoading = controller.isLoading.value;

          final hasAlerts = controller.items.any((p) => p.alerts.isNotEmpty);

          final filtered = controller.filteredItems;

          final effective = controller.alertsOnly.value

              ? filtered.where((p) => p.alerts.isNotEmpty).toList()

              : filtered;

          final summaryEntries =

              _buildPurchaseSummaryEntries(controller.items);

          final sections = _buildPurchaseSections(

            context: context,

            purchases: effective,

          );

          final totalAlerts = controller.items.fold<int>(

            0,

            (sum, purchase) => sum + purchase.alerts.length,

          );

          final alertPurchases =

              controller.items.where((p) => p.alerts.isNotEmpty).length;



          return RefreshIndicator(

            color: context.themePrimary,

            backgroundColor: context.themeSurface,

            onRefresh: controller.load,

            child: CustomScrollView(

              physics: const BouncingScrollPhysics(

                parent: AlwaysScrollableScrollPhysics(),

              ),

              slivers: [

                SliverToBoxAdapter(child: SizedBox(height: 12)),

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),

                    child: _PurchaseSearchField(controller: controller),

                  ),

                ),

                if (isLoading)

                  const SliverToBoxAdapter(

                    child: Padding(

                      padding: EdgeInsets.symmetric(horizontal: 16),

                      child: LinearProgressIndicator(minHeight: 2),

                    ),

                  ),

                if (summaryEntries.isNotEmpty)

                  SliverToBoxAdapter(

                    child: Padding(

                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),

                      child: _PurchaseSummaryRow(

                        entries: summaryEntries,

                        selectedKey: controller.statusFilter.value,

                        onSelect: controller.setStatusFilter,

                      ),

                    ),

                  ),

                SliverToBoxAdapter(
                  child: _ActiveFiltersBar(controller: controller),
                ),

                SliverToBoxAdapter(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                    child: _PurchaseFiltersBar(controller: controller),

                  ),

                ),

                if (hasAlerts) ...[

                  SliverToBoxAdapter(

                    child: Padding(

                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),

                      child: _PurchaseAlertsSummary(

                        totalAlerts: totalAlerts,

                        purchaseCount: alertPurchases,

                        onTap: () => _openAlertSummaryBottomSheet(context),

                      ),

                    ),

                  ),

                  SliverToBoxAdapter(

                    child: Padding(

                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

                      child: Align(

                        alignment: Alignment.centerLeft,

                        child: FilterChip(

                          avatar: const Icon(

                            Icons.warning_amber_rounded,

                            color: Colors.orangeAccent,

                            size: 18,

                          ),

                          label: const Text(

                            'Mostrar apenas compras com alertas',

                          ),

                          labelStyle: const TextStyle(color: Colors.white),

                          visualDensity: VisualDensity.compact,

                          selected: controller.alertsOnly.value,

                          onSelected: (_) => controller.toggleAlertsOnly(),

                          backgroundColor:

                              Colors.orangeAccent.withValues(alpha: 0.08),

                          selectedColor:

                              Colors.orangeAccent.withValues(alpha: 0.18),

                          checkmarkColor: Colors.white,

                          showCheckmark: controller.alertsOnly.value,

                          side: BorderSide(

                            color:

                                controller.alertsOnly.value

                                    ? Colors.orangeAccent

                                    : Colors.orangeAccent.withValues(

                                      alpha: 0.4,

                                    ),

                          ),

                        ),

                      ),

                    ),

                  ),

                ],

                if (sections.isNotEmpty)

                  SliverList(

                    delegate: SliverChildListDelegate(sections),

                  )

                else

                  SliverFillRemaining(

                    hasScrollBody: false,

                    child: _PurchasesEmptyState(

                      hasAlerts: hasAlerts,

                      hasFiltersApplied:

                          controller.statusFilter.value != 'all' ||

                          controller.filter.value.isNotEmpty ||

                          controller.monthFilter.value != null ||

                          controller.alertsOnly.value,

                    ),

                  ),

                SliverToBoxAdapter(child: SizedBox(height: 32)),

              ],

            ),

          );

        }),
      ),
    );
  }

  List<Widget> _buildPurchaseSections({
    required BuildContext context,
    required List<PurchaseModel> purchases,
  }) {
    final pending = purchases.where(controller.isOpenPurchase).toList();
    final received = purchases
        .where((p) => controller.statusLabel(p.status).toLowerCase() == 'recebida')
        .toList();
    final canceled = purchases.where((p) {
      final status = p.status.toLowerCase();
      return status == 'canceled' || status == 'cancelled';
    }).toList();

    final sections = <Widget>[];
    void addSection(String title, List<PurchaseModel> data) {
      if (data.isEmpty) return;
      sections.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      sections.addAll(
        List.generate(data.length, (index) {
          final purchase = data[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              index == data.length - 1 ? 16 : 12,
            ),
            child: _PurchaseCard(
              purchase: purchase,
              controller: controller,
              onDetails: () => _openPurchaseDetailsBottomSheet(
                context,
                purchase,
              ),
              onReceive:
                  controller.canReceive(purchase)
                      ? () => _openReceiveBottomSheet(context, purchase.id)
                      : null,
            ),
          );
        }),
      );
    }

    addSection('Em aberto', pending);
    addSection('Recebidas', received);
    addSection('Canceladas', canceled);
    return sections;
  }

  List<_PurchaseSummaryInfo> _buildPurchaseSummaryEntries(
    List<PurchaseModel> purchases,
  ) {
    if (purchases.isEmpty) return [];
    final total = purchases.length;
    final pending = purchases.where(controller.isOpenPurchase).length;
    final received = purchases
        .where((p) => controller.statusLabel(p.status).toLowerCase() == 'recebida')
        .length;
    final canceled = purchases.where((p) {
      final status = p.status.toLowerCase();
      return status == 'canceled' || status == 'cancelled';
    }).length;
    final totalValue = purchases.fold<double>(
      0,
      (sum, item) => sum + controller.totalFor(item),
    );

    return [
      _PurchaseSummaryInfo(
        key: 'all',
        label: 'Todas',
        value: total.toString(),
        subtitle: _purchaseCurrencyFormatter.format(totalValue),
        color: Colors.blueAccent,
        icon: Icons.receipt_long_outlined,
      ),
      _PurchaseSummaryInfo(
        key: 'pending',
        label: 'Pendentes',
        value: pending.toString(),
        color: Colors.amberAccent,
        icon: Icons.timelapse_outlined,
      ),
      _PurchaseSummaryInfo(
        key: 'received',
        label: 'Recebidas',
        value: received.toString(),
        color: Colors.greenAccent,
        icon: Icons.inventory_2_outlined,
      ),
      _PurchaseSummaryInfo(
        key: 'canceled',
        label: 'Canceladas',
        value: canceled.toString(),
        color: Colors.redAccent,
        icon: Icons.cancel_outlined,
      ),
    ];
  }


void _openPurchaseDetailsBottomSheet(
  BuildContext context,
  PurchaseModel p,
) async {
  final items = p.items;
  final ctrl = Get.find<PurchasesController>();
  await ctrl.ensureItemNamesLoaded();
  if (!context.mounted) return;
  final names = Map<String, String>.from(ctrl.itemNames);
  final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool hasScheduledAlertDialog = false;
  Future<String?> promptWorkflowInput({
    required BuildContext context,
    required String title,
    required String label,
  }) async {
    final textCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.themeSurface,
        title: Text(title),
        content: TextField(
          controller: textCtrl,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(textCtrl.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    textCtrl.dispose();
    if (result == null) return null;
    return result.isEmpty ? null : result;
  }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final statusPt = () {
          final s = p.status.toLowerCase();
          if (s == 'ordered') return 'Pedido';
          if (s == 'received') return 'Recebida';
          if (s == 'canceled' || s == 'cancelled') return 'Cancelada';
          return p.status;
        }();
        final subtotal =
            (p.subtotal ??
                items.fold<double>(0, (sum, e) => sum + (e.qty * e.unitCost)));
        final freight = p.freight ?? 0;
        final total = (p.total > 0) ? p.total : subtotal + freight;
        final dueDate = p.paymentDueDate?.toLocal();
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        final bool isOverdue =
            dueDate != null && dueDate.isBefore(startOfToday);
        final dueDateText =
            dueDate != null
                ? 'Vencimento: ${DateFormat('dd/MM/yyyy').format(dueDate)}${isOverdue ? ' (em atraso)' : ''}'
                : null;
        if (!hasScheduledAlertDialog && p.alerts.isNotEmpty) {
          hasScheduledAlertDialog = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (sheetCtx.mounted) {
              _showAlertsDialog(sheetCtx, p.alerts);
            }
          });
        }
        final normalizedStatus = p.status.toLowerCase();
        final workflowButtons = <Widget>[];
        final isTerminalStatus =
            normalizedStatus == 'received' ||
            normalizedStatus == 'canceled' ||
            normalizedStatus == 'cancelled';
        final canReceivePurchase = ctrl.canReceive(p);
        void closeSheet() {
          if (sheetCtx.mounted) {
            Navigator.of(sheetCtx).pop();
          }
        }
        if (normalizedStatus == 'draft' || normalizedStatus == 'pending') {
          workflowButtons.add(
            FilledButton.icon(
              onPressed: () async {
                final notes = await promptWorkflowInput(
                  context: sheetCtx,
                  title: 'Enviar para aprovacao',
                  label: 'Notas (opcional)',
                );
                await ctrl.submitPurchase(p.id, notes: notes);
                closeSheet();
              },
              icon: const Icon(Icons.send),
              label: const Text('Enviar p/ aprov.'),
            ),
          );
        } else if (normalizedStatus == 'submitted') {
          workflowButtons.add(
            FilledButton.icon(
              onPressed: () async {
                final notes = await promptWorkflowInput(
                  context: sheetCtx,
                  title: 'Aprovar compra',
                  label: 'Notas (opcional)',
                );
                await ctrl.approvePurchase(p.id, notes: notes);
                closeSheet();
              },
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Aprovar compra'),
            ),
          );
        } else if (normalizedStatus == 'approved') {
          workflowButtons.add(
            FilledButton.icon(
              onPressed: () async {
                final code = await promptWorkflowInput(
                  context: sheetCtx,
                  title: 'Marcar como pedido',
                  label: 'Codigo do pedido (opcional)',
                );
                await ctrl.markAsOrdered(p.id, externalId: code);
                closeSheet();
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('Marcar como pedido'),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalhes da compra',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar compra',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: () async {
                      Navigator.of(sheetCtx, rootNavigator: true).pop();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 120),
                      );
                      if (!context.mounted) return;
                      _openEditBottomSheet(context, p);
                    },
                  ),
                ],
              ),
              if (workflowButtons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: workflowButtons,
                ),
              ],
              const SizedBox(height: 8),
              if (p.alerts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: p.alerts
                        .map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PurchaseAlertCard(alert: alert),
                          ),
                        )
                        .toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PurchaseCategoriesSummary(
                  classifications: p.classifications,
                  currency: currency,
                ),
              ),
              Text(
                'Fornecedor: ${Get.find<PurchasesController>().supplierNameFor(p.supplierId)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Status: $statusPt',
                style: const TextStyle(color: Colors.white70),
              ),
              if (dueDateText != null)
                Text(
                  dueDateText,
                  style: TextStyle(
                    color: isOverdue ? Colors.orangeAccent : Colors.white60,
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              if (p.createdAt != null)
                Text(
                  'Criada em: ${DateFormat('dd/MM/yyyy HH:mm').format(p.createdAt!.toLocal())}',
                  style: const TextStyle(color: Colors.white54),
                ),
              if (p.receivedAt != null)
                Text(
                  'Recebida em: ${DateFormat('dd/MM/yyyy HH:mm').format(p.receivedAt!.toLocal())}',
                  style: const TextStyle(color: Colors.white54),
                ),
              if ((p.notes ?? '').isNotEmpty)
                Text(
                'Observações: ${p.notes}',
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 12),
              const Text(
                'Itens',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder:
                      (_, __) =>
                          const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final name = names[it.itemId] ?? it.itemId;
                    final lineTotal = it.qty * it.unitCost;
                    return ListTile(
                      dense: true,
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qtd: ${it.qty} - Unit: ${currency.format(it.unitCost)} - Total: ${currency.format(lineTotal)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if ((it.orderId ?? '').isNotEmpty ||
                              (it.costCenterId ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if ((it.orderId ?? '').isNotEmpty)
                                  Chip(
                                    label: Text('OS: ${it.orderId}'),
                                    backgroundColor: Colors.white12,
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                                if ((it.costCenterId ?? '').isNotEmpty)
                                  Chip(
                                    label: Text(
                                      'Centro: ${it.costCenterId}',
                                    ),
                                    backgroundColor: Colors.white12,
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Subtotal: ',
                    style: TextStyle(color: Colors.white54),
                  ),
                  Text(
                    currency.format(subtotal),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              if (freight > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Frete: ',
                      style: TextStyle(color: Colors.white54),
                    ),
                    Text(
                      currency.format(freight),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Total: ',
                    style: TextStyle(color: Colors.white54),
                  ),
                  Text(
                    currency.format(total),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (p.history.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Historico do workflow',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _PurchaseHistoryTimeline(entries: p.history),
              ],
              if (canReceivePurchase)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeGreen,
                    ),
                    onPressed: () => _openReceiveBottomSheet(context, p.id),
                    child: const Text('Marcar como recebida'),
                  ),
                )
              else if (!isTerminalStatus) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    'Finalize o pedido (status "Pedido") para liberar o recebimento.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAlertSummaryBottomSheet(BuildContext context) {
    final purchases =
        controller.items
            .where((purchase) => purchase.alerts.isNotEmpty)
            .toList();
    if (purchases.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Compras com alerta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: purchases.length,
                  separatorBuilder:
                      (_, __) => const Divider(color: Colors.white12),
                  itemBuilder: (_, index) {
                    final purchase = purchases[index];
                    final supplier = controller.supplierNameFor(
                      purchase.supplierId,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                      ),
                      title: Text(
                        supplier,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        purchase.alerts.first.message,
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              _openPurchaseDetailsBottomSheet(
                                context,
                                purchase,
                              );
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

void _openCreateBottomSheet(
  BuildContext context, {
  PurchasePrefillData? prefill,
}) {
  final formKey = GlobalKey<FormState>();
  final notesCtrl = TextEditingController();
  final supplierNameCtrl = TextEditingController();
  final supplierId = RxnString();
  final Rxn<SupplierModel> selectedSupplier = Rxn<SupplierModel>();
  final Map<String, SupplierModel> supplierCache = {};
  final RxList<CostCenterModel> costCenters = <CostCenterModel>[].obs;
  final RxBool costCentersLoading = false.obs;
  final RxnString selectedCostCenterId = RxnString(prefill?.costCenterId);

  final itemNameCtrl = TextEditingController();
  String? selectedItemId;
  final qtyCtrl = TextEditingController(text: '1');
  final unitCtrl = TextEditingController(text: '0');
  final freightCtrl = TextEditingController();
  final Rxn<DateTime> paymentDueDate = Rxn<DateTime>();
  final status = 'ordered'.obs;
  final items = <PurchaseItemModel>[].obs;
  final displayItems = <Map<String, dynamic>>[].obs;
  final ctrl = Get.find<PurchasesController>();

  Future<void> loadCostCenters() async {
    if (!Get.isRegistered<CostCentersService>()) return;
    costCentersLoading(true);
    try {
      final service = Get.find<CostCentersService>();
      final result = await service.list(includeInactive: false);
      final active = result.where((center) => center.active).toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      costCenters.assignAll(active);
      final current = selectedCostCenterId.value;
      if (current != null && current.isNotEmpty) {
        final exists = active.any((center) => center.id == current);
        if (!exists) {
          selectedCostCenterId.value = null;
        }
      }
    } catch (_) {
      // ignore load failures; user can salvar mesmo sem centros
    } finally {
      costCentersLoading(false);
    }
  }

  unawaited(loadCostCenters());

  Future<void> hydrateSupplier(String supplier) async {
    if ((supplier).isEmpty) return;
    if (supplierCache.containsKey(supplier)) {
      selectedSupplier.value = supplierCache[supplier];
      return;
    }
    if (!Get.isRegistered<SuppliersService>()) return;
    try {
      final service = Get.find<SuppliersService>();
      final result = await service.list(text: '');
      for (final entry in result) {
        supplierCache[entry.id] = entry;
        if (entry.id == supplier) {
          selectedSupplier.value = entry;
        }
      }
    } catch (_) {}
  }

  String labelForCostCenter(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final center in costCenters) {
      if (center.id == id) return center.name;
    }
    return id;
  }

  Future<void> editLineMetadata(int index) async {
    if (index < 0 || index >= items.length) return;
    final current = items[index];
    final orderCtrl = TextEditingController(text: current.orderId ?? '');
    String? lineCostCenter = current.costCenterId ?? selectedCostCenterId.value;
    final centers = costCenters.toList(growable: false);
    String? costCenterError;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vincular OS / Centro de custo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID da OS (opcional)',
                    suffixIcon: Icon(Icons.confirmation_num_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: lineCostCenter,
                  dropdownColor: context.themeDark,
                  decoration: InputDecoration(
                    labelText: 'Centro de custo',
                    helperText: centers.isEmpty
                        ? 'Nenhum centro de custo disponível.'
                        : 'Selecione o centro utilizado nesta linha.',
                    errorText: costCenterError,
                  ),
                  items: centers
                      .map(
                        (center) => DropdownMenuItem(
                          value: center.id,
                          child: Text(center.name),
                        ),
                      )
                      .toList(),
                  onChanged: centers.isEmpty
                      ? null
                      : (value) => setState(() {
                            lineCostCenter = value;
                            costCenterError = null;
                          }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: centers.isEmpty
                            ? null
                            : () {
                                if ((lineCostCenter ?? '').isEmpty) {
                                  setState(
                                    () => costCenterError =
                                        'Selecione o centro de custo',
                                  );
                                  return;
                                }
                                Navigator.of(ctx).pop(true);
                              },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    if (applied == true) {
      final orderId =
          orderCtrl.text.trim().isEmpty ? null : orderCtrl.text.trim();
      final costCenter =
          (lineCostCenter ?? '').trim().isEmpty ? null : lineCostCenter;
      items[index] = current.copyWith(
        orderId: orderId,
        costCenterId: costCenter,
      );
      items.refresh();
      displayItems[index]['orderId'] = orderId;
      displayItems[index]['costCenterId'] = costCenter;
      displayItems.refresh();
    }
    orderCtrl.dispose();
  }


  if (prefill?.supplierId != null && prefill!.supplierId!.isNotEmpty) {
    supplierId.value = prefill.supplierId;
    supplierNameCtrl.text = ctrl.supplierNameFor(prefill.supplierId!);
    unawaited(hydrateSupplier(prefill.supplierId!));
  }
  if (prefill?.items.isNotEmpty ?? false) {
    for (final entry in prefill!.items) {
      if (entry.quantity <= 0) continue;
      items.add(
        PurchaseItemModel(
          itemId: entry.itemId,
          qty: entry.quantity,
          unitCost: entry.unitCost,
          orderId: entry.orderId,
          costCenterId: entry.costCenterId,
        ),
      );
      displayItems.add({
        'name': entry.itemName ?? entry.itemId,
        'qty': entry.quantity,
        'unit': entry.unitCost,
        'orderId': entry.orderId,
        'costCenterId': entry.costCenterId,
      });
    }
  }

  Future<void> pickSupplier() async {
    final service = Get.find<SuppliersService>();
    final initial = await service.list(text: '');
    final list = RxList<SupplierModel>(initial);
    for (final entry in initial) {
      supplierCache[entry.id] = entry;
    }
    final searchCtrl = TextEditingController();
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Get.context!.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar fornecedor',
              ),
              onChanged: (v) async {
                final res = await service.list(text: v.trim());
                list.assignAll(res);
                for (final entry in res) {
                  supplierCache[entry.id] = entry;
                }
              },
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Obx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final supplier = list[i];
                    final subtitleParts = _supplierContactParts(supplier);
                    return ListTile(
                      title: Text(supplier.name),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(subtitleParts.join(' • ')),
                      onTap: () {
                        supplierCache[supplier.id] = supplier;
                        supplierId.value = supplier.id;
                        supplierNameCtrl.text = supplier.name;
                        selectedSupplier.value = supplier;
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

    Future<void> pickItem() async {
      final inv = Get.find<InventoryService>();
      final list = RxList<InventoryItemModel>(await inv.getItems(text: ''));
      final searchCtrl = TextEditingController();
      await Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Get.context!.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar item (nome/sku)',
                ),
                onChanged: (v) async {
                  final res = await inv.getItems(text: v.trim());
                  list.assignAll(res);
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    // Abrir modal de novo item (mesmo do estoque)
                    InventoryPage.showAddItemModal(context: Get.context!);
                    // aguarda fechar
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar novo produto'),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Obx(
                  () => ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder:
                        (_, i) => ListTile(
                          title: Text(list[i].name),
                          subtitle: Text(
                            'SKU: ${list[i].sku}  -  Em estoque: ${list[i].onHand} ${list[i].unit}',
                          ),
                          onTap: () {
                            selectedItemId = list[i].id;
                            itemNameCtrl.text = list[i].name;
                            Get.back();
                          },
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      builder:
          (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Obx(() {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Nova compra',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                Obx(() {
                  final hasSupplier =
                      (supplierId.value ?? '').isNotEmpty;
                  final supplierDetails =
                      selectedSupplier.value ??
                      (hasSupplier ? supplierCache[supplierId.value] : null);
                  final helperParts = _supplierContactParts(
                    supplierDetails,
                    includeLabels: true,
                  );
                  final helperText =
                      hasSupplier
                          ? helperParts.isNotEmpty
                              ? helperParts.join(' • ')
                              : 'Fornecedor selecionado. Toque para alterar.'
                          : 'Toque para escolher um fornecedor cadastrado';
                  return TextFormField(
                    controller: supplierNameCtrl,
                    readOnly: true,
                    onTap: pickSupplier,
                    validator:
                        (_) =>
                            supplierId.value == null
                                ? 'Selecione o fornecedor'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Fornecedor',
                      helperText: helperText,
                      hintText: hasSupplier ? null : 'Selecionar fornecedor',
                      suffixIcon: SizedBox(
                        width: hasSupplier ? 72 : 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (hasSupplier)
                              IconButton(
                                tooltip: 'Limpar seleção',
                                onPressed: () {
                                  supplierId.value = null;
                                  supplierNameCtrl.clear();
                                  selectedSupplier.value = null;
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            const Icon(Icons.search),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Obx(() {
                  final loading = costCentersLoading.value;
                  final centers = costCenters.toList(growable: false);
                  final selected = selectedCostCenterId.value;
                  final hasSelection =
                      selected != null &&
                      centers.any((center) => center.id == selected);
                  final helper =
                      loading
                          ? 'Carregando centros de custo...'
                          : centers.isEmpty
                          ? 'Nenhum centro de custo ativo encontrado.'
                          : 'Selecione o centro responsável por esta compra.';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: hasSelection ? selected : null,
                        isExpanded: true,
                        dropdownColor: context.themeDark,
                        iconEnabledColor: Colors.white,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (_) {
                          if (centers.isEmpty) {
                            return 'Cadastre ao menos um centro de custo';
                          }
                          if ((selectedCostCenterId.value ?? '').isEmpty) {
                            return 'Selecione o centro de custo';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Centro de custo',
                          helperText: helper,
                          suffixIcon:
                              loading
                                  ? Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                  : hasSelection
                                  ? IconButton(
                                    tooltip: 'Limpar seleção',
                                    onPressed: () {
                                      selectedCostCenterId.value = null;
                                    },
                                    icon: const Icon(Icons.clear),
                                  )
                                  : IconButton(
                                    tooltip: 'Atualizar lista',
                                    onPressed: () => loadCostCenters(),
                                    icon: const Icon(Icons.refresh),
                                  ),
                        ),
                        items:
                            centers
                                .map(
                                  (center) => DropdownMenuItem(
                                    value: center.id,
                                    child: Text(center.name),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            centers.isEmpty
                                ? null
                                : (value) => selectedCostCenterId.value = value,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => Get.toNamed('/finance/cost-centers'),
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('Gerenciar centros'),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: status.value,
                            dropdownColor: context.themeDark,
                            iconEnabledColor: Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: 'ordered',
                                child: Text(
                                  'Pedido',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'received',
                                child: Text(
                                  'Recebida',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            onChanged: (v) => status.value = v ?? 'ordered',
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: freightCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            inputFormatters: [
                              MoneyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              final parsed = _parseCurrencyText(value);
                              if (parsed == null) return 'Frete inválido';
                              if (parsed < 0) {
                                return 'Frete deve ser maior ou igual a zero';
                              }
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Frete (opcional)',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: itemNameCtrl,
                      readOnly: true,
                      onTap: pickItem,
                      validator:
                          (v) =>
                              (selectedItemId == null && items.isEmpty)
                                  ? 'Selecione o item'
                                  : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Item',
                        labelStyle: TextStyle(color: Colors.white),
                        suffixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            validator:
                                (v) =>
                                    selectedItemId == null
                                        ? null
                                        : FormValidators.validateNumber(
                                          v,
                                          fieldName: 'Qtd',
                                          positive: true,
                                        ),
                            decoration: const InputDecoration(
                              labelText: 'Qtd',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: unitCtrl,
                            keyboardType: TextInputType.number,
                            validator:
                                (v) =>
                                    selectedItemId == null
                                        ? null
                                        : FormValidators.validateNumber(
                                          v,
                                          fieldName: 'Unit',
                                          positive: true,
                                        ),
                            decoration: const InputDecoration(
                              labelText: 'Custo unit.',
                              prefixText: 'R\$ ',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            final id = selectedItemId ?? '';
                            final qty =
                                double.tryParse(
                                  qtyCtrl.text.trim().replaceAll(',', '.'),
                                ) ??
                                0;
                            final unit =
                                double.tryParse(
                                  unitCtrl.text.trim().replaceAll(',', '.'),
                                ) ??
                                0;
                            if (id.isEmpty || qty <= 0 || unit <= 0) return;
                          items.add(
                            PurchaseItemModel(
                              itemId: id,
                              qty: qty,
                              unitCost: unit,
                              costCenterId: selectedCostCenterId.value,
                            ),
                          );
                          displayItems.add({
                            'name': itemNameCtrl.text,
                            'qty': qty,
                            'unit': unit,
                            'orderId': null,
                            'costCenterId': selectedCostCenterId.value,
                          });
                            selectedItemId = null;
                            itemNameCtrl.clear();
                            qtyCtrl.text = '1';
                            unitCtrl.text = '0';
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (displayItems.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayItems.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                height: 1,
                                color: Colors.white12,
                              ),
                          itemBuilder: (_, i) {
                            final it = displayItems[i];
                            final orderId = it['orderId'] as String?;
                            final lineCostCenter = it['costCenterId'] as String?;
                            final costCenterLabel =
                                labelForCostCenter(lineCostCenter);
                            return ListTile(
                              dense: true,
                              title: Text(
                                it['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Qtd: ${it['qty']} - Unit: R\$ ${(it['unit'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  if ((orderId ?? '').isNotEmpty ||
                                      (lineCostCenter ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if ((orderId ?? '').isNotEmpty)
                                          Chip(
                                            label: Text('OS: $orderId'),
                                            backgroundColor: Colors.white12,
                                            labelStyle:
                                                const TextStyle(color: Colors.white),
                                          ),
                                        if ((lineCostCenter ?? '').isNotEmpty)
                                          Chip(
                                            label: Text('Centro: $costCenterLabel'),
                                            backgroundColor: Colors.white12,
                                            labelStyle:
                                                const TextStyle(color: Colors.white),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Vincular OS/centro',
                                    icon: const Icon(
                                      Icons.link,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () => editLineMetadata(i),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      items.removeAt(i);
                                      displayItems.removeAt(i);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.themeGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed:
                                  (supplierId.value == null || items.isEmpty)
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        final freight = _parseCurrencyText(
                                          freightCtrl.text,
                                        );
                                         final created = await ctrl.create(
                                           supplierId: supplierId.value!,
                                           items: items.toList(),
                                           status: status.value,
                                           freight: freight,
                                           notes:
                                               notesCtrl.text.trim().isNotEmpty
                                                   ? notesCtrl.text.trim()
                                                   : null,
                                           paymentDueDate: paymentDueDate.value,
                                         );
                                        if (created != null) {
                                          if (status.value == 'received' &&
                                              created.status.toLowerCase() !=
                                                  'received') {
                                            await ctrl.receive(
                                              created.id,
                                              receivedAt: DateTime.now(),
                                            );
                                          } else if (created.status
                                                      .toLowerCase() ==
                                                  'received' &&
                                              Get.isRegistered<
                                                InventoryController
                                              >()) {
                                            final inventoryController =
                                                Get.find<InventoryController>();
                                            await inventoryController
                                                .refreshCurrentView(
                                                  showLoader: false,
                                                );
                                            inventoryController.scheduleRefresh(
                                              delay: const Duration(
                                                milliseconds: 400,
                                              ),
                                              showLoader: false,
                                            );
                                          }
                                          await ctrl.load();
                                          if (!context.mounted) return;
                                          if (created.alerts.isNotEmpty) {
                                            await _showAlertsDialog(
                                              context,
                                              created.alerts,
                                            );
                                            if (!context.mounted) return;
                                          }
                                          final navigator = Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          );
                                          if (navigator.canPop()) {
                                            navigator.pop();
                                          }
                                        }
                                      },
                              child: Text(
                                'Salvar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.themeGray,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 45,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () => Get.back(),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
    ).whenComplete(() {
      notesCtrl.dispose();
      supplierNameCtrl.dispose();
      itemNameCtrl.dispose();
      qtyCtrl.dispose();
      unitCtrl.dispose();
      freightCtrl.dispose();
    });
  }

  void _openReceiveBottomSheet(BuildContext context, String purchaseId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dar entrada na compra',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      final ctrl = Get.find<PurchasesController>();
                      // Fecha antes para evitar conflito de overlay/snackbar
                      Get.back();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 80),
                      );
                      await ctrl.receive(purchaseId);
                      await ctrl.load();
                    },
                    child: Text(
                      'Receber',
                      style: TextStyle(
                        color: context.themeGray,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

void _openEditBottomSheet(BuildContext context, PurchaseModel original) async {
  final formKey = GlobalKey<FormState>();
  final notesCtrl = TextEditingController(text: original.notes ?? '');
  final supplierNameCtrl = TextEditingController(
    text: Get.find<PurchasesController>().supplierNameFor(original.supplierId),
  );
  final supplierId = RxnString(original.supplierId);
  final Rxn<SupplierModel> selectedSupplier = Rxn<SupplierModel>();
  final Map<String, SupplierModel> supplierCache = {};
  final RxList<CostCenterModel> costCenters = <CostCenterModel>[].obs;
  final RxBool costCentersLoading = false.obs;
  final RxnString selectedCostCenterId = RxnString(original.costCenterId);

  final itemNameCtrl = TextEditingController();
  String? selectedItemId;
  final qtyCtrl = TextEditingController(text: '1');
  final unitCtrl = TextEditingController(text: '0');
  final freightCtrl = TextEditingController(
    text:
        (original.freight ?? 0) > 0
            ? _purchaseCurrencyFormatter.format(original.freight)
            : '',
  );
  final status = original.status.obs;
  final items = RxList<PurchaseItemModel>(
    original.items
        .map(
          (e) => PurchaseItemModel(
            itemId: e.itemId,
            qty: e.qty,
            unitCost: e.unitCost,
          ),
        )
        .toList(),
  );
  final displayItems = <Map<String, dynamic>>[].obs;
  final Rxn<DateTime> paymentDueDate = Rxn<DateTime>(original.paymentDueDate);

  Future<void> loadCostCenters() async {
    if (!Get.isRegistered<CostCentersService>()) return;
    costCentersLoading(true);
    try {
      final service = Get.find<CostCentersService>();
      final result = await service.list(includeInactive: false);
      final active = result.where((center) => center.active).toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      costCenters.assignAll(active);
      final current = selectedCostCenterId.value;
      if (current != null && current.isNotEmpty) {
        final exists = active.any((center) => center.id == current);
        if (!exists) {
          selectedCostCenterId.value = null;
        }
      }
    } catch (_) {
      // ignore load failures
    } finally {
      costCentersLoading(false);
    }
  }

  unawaited(loadCostCenters());

  Future<void> hydrateSupplier(String supplier) async {
    if ((supplier).isEmpty) return;
    if (supplierCache.containsKey(supplier)) {
      selectedSupplier.value = supplierCache[supplier];
      return;
    }
    if (!Get.isRegistered<SuppliersService>()) return;
    try {
      final service = Get.find<SuppliersService>();
      final result = await service.list(text: '');
      for (final entry in result) {
        supplierCache[entry.id] = entry;
        if (entry.id == supplier) {
          selectedSupplier.value = entry;
        }
      }
    } catch (_) {}
  }

  unawaited(hydrateSupplier(original.supplierId));

  String labelForCostCenter(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final center in costCenters) {
      if (center.id == id) return center.name;
    }
    return id;
  }

  Future<void> editLineMetadata(int index) async {
    if (index < 0 || index >= items.length) return;
    final current = items[index];
    final orderCtrl = TextEditingController(text: current.orderId ?? '');
    String? lineCostCenter = current.costCenterId ?? selectedCostCenterId.value;
    final centers = costCenters.toList(growable: false);
    String? costCenterError;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vincular OS / Centro de custo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID da OS (opcional)',
                    suffixIcon: Icon(Icons.confirmation_num_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: lineCostCenter,
                  dropdownColor: context.themeDark,
                  decoration: InputDecoration(
                    labelText: 'Centro de custo',
                    helperText: centers.isEmpty
                        ? 'Nenhum centro de custo disponível.'
                        : 'Selecione o centro utilizado nesta linha.',
                    errorText: costCenterError,
                  ),
                  items: centers
                      .map(
                        (center) => DropdownMenuItem(
                          value: center.id,
                          child: Text(center.name),
                        ),
                      )
                      .toList(),
                  onChanged: centers.isEmpty
                      ? null
                      : (value) => setState(() {
                            lineCostCenter = value;
                            costCenterError = null;
                          }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: centers.isEmpty
                            ? null
                            : () {
                                if ((lineCostCenter ?? '').isEmpty) {
                                  setState(
                                    () => costCenterError =
                                        'Selecione o centro de custo',
                                  );
                                  return;
                                }
                                Navigator.of(ctx).pop(true);
                              },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    if (applied == true) {
      final orderId =
          orderCtrl.text.trim().isEmpty ? null : orderCtrl.text.trim();
      final costCenter =
          (lineCostCenter ?? '').trim().isEmpty ? null : lineCostCenter;
      items[index] = current.copyWith(
        orderId: orderId,
        costCenterId: costCenter,
      );
      items.refresh();
      displayItems[index]['orderId'] = orderId;
      displayItems[index]['costCenterId'] = costCenter;
      displayItems.refresh();
    }
    orderCtrl.dispose();
  }


  await Get.find<PurchasesController>().ensureItemNamesLoaded();
  if (!context.mounted) return;
  final names = Map<String, String>.from(
    Get.find<PurchasesController>().itemNames,
  );
  for (final it in items) {
    displayItems.add({
      'name': names[it.itemId] ?? it.itemId,
      'qty': it.qty,
      'unit': it.unitCost,
      'orderId': it.orderId,
      'costCenterId': it.costCenterId,
    });
  }

  Future<void> pickSupplier() async {
    final service = Get.find<SuppliersService>();
    final initial = await service.list(text: '');
    final list = RxList<SupplierModel>(initial);
    for (final entry in initial) {
      supplierCache[entry.id] = entry;
    }
    final searchCtrl = TextEditingController();
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Get.context!.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar fornecedor',
              ),
              onChanged: (v) async {
                final res = await service.list(text: v.trim());
                list.assignAll(res);
                for (final entry in res) {
                  supplierCache[entry.id] = entry;
                }
              },
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Obx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final supplier = list[i];
                    final subtitleParts = _supplierContactParts(supplier);
                    return ListTile(
                      title: Text(supplier.name),
                      subtitle: subtitleParts.isEmpty
                          ? null
                          : Text(subtitleParts.join(' • ')),
                      onTap: () {
                        supplierCache[supplier.id] = supplier;
                        supplierId.value = supplier.id;
                        supplierNameCtrl.text = supplier.name;
                        selectedSupplier.value = supplier;
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> pickItem() async {
    final inv = Get.find<InventoryService>();
    final list = RxList<InventoryItemModel>(await inv.getItems(text: ''));
    final searchCtrl = TextEditingController();
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Get.context!.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar item (nome/sku)',
              ),
              onChanged: (v) async {
                final res = await inv.getItems(text: v.trim());
                list.assignAll(res);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  InventoryPage.showAddItemModal(context: Get.context!);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar novo produto'),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Obx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder:
                      (_, i) => ListTile(
                        title: Text(list[i].name),
                        subtitle: Text(
                          'SKU: ${list[i].sku}  -  Em estoque: ${list[i].onHand} ${list[i].unit}',
                        ),
                        onTap: () {
                          selectedItemId = list[i].id;
                          itemNameCtrl.text = list[i].name;
                          Get.back();
                        },
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isDismissible: false,
    builder:
        (_) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar Compra',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final hasSupplier =
                        (supplierId.value ?? '').isNotEmpty;
                    final supplierDetails =
                        selectedSupplier.value ??
                        (hasSupplier ? supplierCache[supplierId.value] : null);
                    final helperParts = _supplierContactParts(
                      supplierDetails,
                      includeLabels: true,
                    );
                    final helperText =
                        hasSupplier
                            ? helperParts.isNotEmpty
                                ? helperParts.join(' • ')
                                : 'Fornecedor selecionado. Toque para alterar.'
                            : 'Toque para escolher um fornecedor cadastrado';
                    return TextFormField(
                      controller: supplierNameCtrl,
                      readOnly: true,
                      onTap: pickSupplier,
                      validator:
                          (v) =>
                              (supplierId.value == null ||
                                      (supplierId.value?.isEmpty ?? true))
                                  ? 'Selecione o fornecedor'
                                  : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Fornecedor',
                        helperText: helperText,
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: hasSupplier ? null : 'Selecionar fornecedor',
                        suffixIcon: SizedBox(
                          width: hasSupplier ? 72 : 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (hasSupplier)
                                IconButton(
                                  tooltip: 'Limpar seleção',
                                  onPressed: () {
                                    supplierId.value = null;
                                    supplierNameCtrl.clear();
                                    selectedSupplier.value = null;
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              const Icon(Icons.search),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Obx(() {
                    final loading = costCentersLoading.value;
                    final centers = costCenters.toList(growable: false);
                    final selected = selectedCostCenterId.value;
                    final hasSelection =
                        selected != null &&
                        centers.any((center) => center.id == selected);
                    final helper =
                        loading
                            ? 'Carregando centros de custo...'
                            : centers.isEmpty
                            ? 'Nenhum centro de custo ativo encontrado.'
                            : 'Selecione o centro responsável por esta compra.';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: hasSelection ? selected : null,
                          isExpanded: true,
                          dropdownColor: context.themeDark,
                          iconEnabledColor: Colors.white,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (_) {
                            if (centers.isEmpty) {
                              return 'Cadastre ao menos um centro de custo';
                            }
                            if ((selectedCostCenterId.value ?? '').isEmpty) {
                              return 'Selecione o centro de custo';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Centro de custo',
                            helperText: helper,
                            suffixIcon:
                                loading
                                    ? Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                    : hasSelection
                                    ? IconButton(
                                      tooltip: 'Limpar seleção',
                                      onPressed: () {
                                        selectedCostCenterId.value = null;
                                      },
                                      icon: const Icon(Icons.clear),
                                    )
                                    : IconButton(
                                      tooltip: 'Atualizar lista',
                                      onPressed: () => loadCostCenters(),
                                      icon: const Icon(Icons.refresh),
                                    ),
                          ),
                          items:
                              centers
                                  .map(
                                    (center) => DropdownMenuItem(
                                      value: center.id,
                                      child: Text(center.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              centers.isEmpty
                                  ? null
                                  : (value) => selectedCostCenterId.value = value,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Get.toNamed('/finance/cost-centers'),
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Gerenciar centros'),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status.value,
                          dropdownColor: context.themeDark,
                          iconEnabledColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                              value: 'ordered',
                              child: Text(
                                'Pedido',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'received',
                              child: Text(
                                'Recebida',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                          onChanged: (v) => status.value = v ?? 'ordered',
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: freightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                          inputFormatters: [
                            MoneyInputFormatter(locale: 'pt_BR', symbol: 'R\$'),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = _parseCurrencyText(value);
                            if (parsed == null) return 'Frete inválido';
                            if (parsed < 0) {
                              return 'Frete deve ser maior ou igual a zero';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Frete (opcional)',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.event,
                              color: Colors.white70,
                            ),
                            label: Text(
                              paymentDueDate.value == null
                                  ? 'Definir vencimento'
                                  : 'Vencimento: ${DateFormat('dd/MM/yyyy').format(paymentDueDate.value!)}',
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: paymentDueDate.value ?? now,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                paymentDueDate.value = picked;
                              }
                            },
                          ),
                        ),
                        if (paymentDueDate.value != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Limpar vencimento',
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                            ),
                            onPressed: () => paymentDueDate.value = null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(
                              Icons.event,
                              color: Colors.white70,
                            ),
                            label: Text(
                              paymentDueDate.value == null
                                  ? 'Definir vencimento'
                                  : 'Vencimento: ${DateFormat('dd/MM/yyyy').format(paymentDueDate.value!)}',
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: paymentDueDate.value ?? now,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                paymentDueDate.value = picked;
                              }
                            },
                          ),
                        ),
                        if (paymentDueDate.value != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Limpar vencimento',
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                            ),
                            onPressed: () => paymentDueDate.value = null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: itemNameCtrl,
                    readOnly: true,
                    onTap: pickItem,
                    validator:
                        (v) =>
                            (selectedItemId == null && items.isEmpty)
                                ? 'Selecione o item'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  selectedItemId == null
                                      ? null
                                      : FormValidators.validateNumber(
                                        v,
                                        fieldName: 'Qtd',
                                        positive: true,
                                      ),
                          decoration: const InputDecoration(
                            labelText: 'Qtd',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: unitCtrl,
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  selectedItemId == null
                                      ? null
                                      : FormValidators.validateNumber(
                                        v,
                                        fieldName: 'Unit',
                                        positive: true,
                                      ),
                          decoration: const InputDecoration(
                            labelText: 'Custo unit.',
                            prefixText: 'R\$ ',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          final id = selectedItemId ?? '';
                          final qty =
                              double.tryParse(
                                qtyCtrl.text.trim().replaceAll(',', '.'),
                              ) ??
                              0;
                          final unit =
                              double.tryParse(
                                unitCtrl.text.trim().replaceAll(',', '.'),
                              ) ??
                              0;
                          if (id.isEmpty || qty <= 0 || unit <= 0) return;
                          final defaultCostCenter = selectedCostCenterId.value;
                          items.add(
                            PurchaseItemModel(
                              itemId: id,
                              qty: qty,
                              unitCost: unit,
                              costCenterId: defaultCostCenter,
                            ),
                          );
                          displayItems.add({
                            'name': itemNameCtrl.text,
                            'qty': qty,
                            'unit': unit,
                            'orderId': null,
                            'costCenterId': defaultCostCenter,
                          });
                          selectedItemId = null;
                          itemNameCtrl.clear();
                          qtyCtrl.text = '1';
                          unitCtrl.text = '0';
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (displayItems.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayItems.length,
                        separatorBuilder:
                            (_, __) =>
                                const Divider(height: 1, color: Colors.white12),
                        itemBuilder: (_, i) {
                          final it = displayItems[i];
                          final orderId = it['orderId'] as String?;
                          final lineCostCenter = it['costCenterId'] as String?;
                          final costCenterLabel =
                              labelForCostCenter(lineCostCenter);
                          return ListTile(
                            dense: true,
                            title: Text(
                              it['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Qtd: ${it['qty']} - Unit: R\$ ${(it['unit'] as double).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if ((orderId ?? '').isNotEmpty ||
                                    (lineCostCenter ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if ((orderId ?? '').isNotEmpty)
                                        Chip(
                                          label: Text('OS: $orderId'),
                                          backgroundColor: Colors.white12,
                                          labelStyle:
                                              const TextStyle(color: Colors.white),
                                        ),
                                      if ((lineCostCenter ?? '').isNotEmpty)
                                        Chip(
                                          label: Text('Centro: $costCenterLabel'),
                                          backgroundColor: Colors.white12,
                                          labelStyle:
                                              const TextStyle(color: Colors.white),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Vincular OS/centro',
                                  icon: const Icon(
                                    Icons.link,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => editLineMetadata(i),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    items.removeAt(i);
                                    displayItems.removeAt(i);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.themeGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed:
                                (supplierId.value == null || items.isEmpty)
                                    ? null
                                    : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                        final freight = _parseCurrencyText(
                                          freightCtrl.text,
                                        );
                                      final ctrl =
                                          Get.find<PurchasesController>();
                                       final updated = await ctrl.updatePurchase(
                                         id: original.id,
                                         supplierId: supplierId.value,
                                         items: items.toList(),
                                         status: status.value,
                                         freight: freight,
                                         notes:
                                             notesCtrl.text.trim().isNotEmpty
                                                 ? notesCtrl.text.trim()
                                                 : null,
                                         paymentDueDate: paymentDueDate.value,
                                       );
                                      if (updated == null) return;
                                      if (status.value == 'received' &&
                                          original.status.toLowerCase() !=
                                              'received') {
                                        await ctrl.receive(
                                          updated.id,
                                          receivedAt: DateTime.now(),
                                        );
                                      }
                                      await ctrl.load();
                                      if (!context.mounted) return;
                                      if (updated.alerts.isNotEmpty) {
                                        await _showAlertsDialog(
                                          context,
                                          updated.alerts,
                                        );
                                        if (!context.mounted) return;
                                      }
                                      final navigator = Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      );
                                      if (navigator.canPop()) {
                                        navigator.pop();
                                      }
                                    },
                            child: Text(
                              'Salvar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.themeGray,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () => Get.back(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
  ).whenComplete(() {
    notesCtrl.dispose();
    supplierNameCtrl.dispose();
    itemNameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    freightCtrl.dispose();
  });
}

Future<void> _showAlertsDialog(
  BuildContext context,
  List<PurchaseAlertModel> alerts,
) async {
  if (alerts.isEmpty) return;
  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: context.themeDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Alertas de custo'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _PurchaseAlertCard(alert: alerts[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Entendi'),
          ),
        ],
      );
    },
  );
}

class _PurchaseSearchField extends StatelessWidget {
  const _PurchaseSearchField({required this.controller});

  final PurchasesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasText = controller.searchTerm.value.isNotEmpty;
      return TextField(
        controller: controller.searchCtrl,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          labelText: 'Buscar por fornecedor, status ou ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              hasText
                  ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.searchCtrl.clear();
                      controller.onSearchChanged('');
                    },
                  )
                  : null,
        ),
      );
    });
  }
}

class _PurchaseFiltersBar extends StatelessWidget {
  const _PurchaseFiltersBar({required this.controller});

  final PurchasesController controller;


  @override

  Widget build(BuildContext context) {

    return Obx(() {

      final years = controller.yearOptions;

      final selectedYear = controller.yearFilter.value;

      final selectedMonth = controller.monthFilter.value;

      final months = controller.monthOptions;

      final monthsWithData = controller.monthsWithDataForYear(selectedYear);



      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.themeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.calendar_month, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text(
                  'Período',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: years
                  .map(
                    (year) => ChoiceChip(
                      label: Text(year.toString()),
                      selected: year == selectedYear,
                      onSelected: (_) => controller.setYearFilter(year),
                      selectedColor: context.themePrimary.withValues(alpha: .25),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: year == selectedYear
                            ? Colors.white
                            : Colors.white70,
                        fontWeight:
                            year == selectedYear ? FontWeight.w600 : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: months.map((month) {
                final hasData = monthsWithData.contains(month.month);
                final selected =
                    selectedMonth != null &&
                    selectedMonth.year == month.year &&
                    selectedMonth.month == month.month;
                final label = _purchaseMonthFormatter
                    .format(month)
                    .replaceAll('.', '')
                    .toUpperCase();
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected:
                      hasData
                          ? (value) =>
                              controller.setMonthFilter(value ? month : null)
                          : null,
                  selectedColor: context.themePrimary.withValues(alpha: .2),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  disabledColor: Colors.white.withValues(alpha: 0.03),
                  labelStyle: TextStyle(
                    color: !hasData
                        ? Colors.white24
                        : selected
                            ? Colors.white
                            : Colors.white70,
                    fontWeight: hasData && selected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
            if (selectedMonth != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => controller.setMonthFilter(null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpar mês'),
                ),
              ),
          ],
        ),
      );
    });
  }
}


class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({required this.controller});

  final PurchasesController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final chips = <Widget>[];
      final searchText = controller.searchTerm.value.trim();
      if (searchText.isNotEmpty) {
        chips.add(
          InputChip(
            avatar: const Icon(Icons.search, size: 16),
            label: Text('Busca: $searchText'),
            onDeleted: () {
              controller.searchCtrl.clear();
              controller.onSearchChanged('');
            },
          ),
        );
      }

      final status = controller.statusFilter.value;
      if (status != 'all') {
        chips.add(
          InputChip(
            avatar: const Icon(Icons.sell_outlined, size: 16),
            label: Text(controller.statusLabel(status)),
            onDeleted: () => controller.setStatusFilter('all'),
          ),
        );
      }

      final month = controller.monthFilter.value;
      if (month != null) {
        final label = _purchaseMonthYearFormatter.format(month).toUpperCase();
        chips.add(
          InputChip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text('Período: $label'),
            onDeleted: () => controller.setMonthFilter(null),
          ),
        );
      }

      if (controller.alertsOnly.value) {
        chips.add(
          InputChip(
            avatar: const Icon(Icons.warning_amber_rounded, size: 16),
            label: const Text('Somente alertas'),
            onDeleted: controller.toggleAlertsOnly,
          ),
        );
      }

      if (chips.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.themeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      controller.hasFiltersApplied ? controller.clearFilters : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpar filtros'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PurchasesEmptyState extends StatelessWidget {

  const _PurchasesEmptyState({

    required this.hasAlerts,

    required this.hasFiltersApplied,

  });



  final bool hasAlerts;

  final bool hasFiltersApplied;



  @override

  Widget build(BuildContext context) {

    final title =

        hasFiltersApplied

            ? 'Nenhuma compra encontrada para os filtros selecionados'

            : 'Ainda não há compras cadastradas';

    final subtitle =

        hasFiltersApplied

            ? 'Revise os filtros ou limpe-os para visualizar outros registros.'

            : 'Use o botão "+" para registrar as próximas compras.';

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 32),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          const Icon(

            Icons.receipt_long_outlined,

            size: 72,

            color: Colors.white38,

          ),

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

            style: const TextStyle(color: Colors.white60),

          ),

          if (hasAlerts)

            Padding(

              padding: const EdgeInsets.only(top: 16),

              child: Text(

                'Existem compras com alertas. Você pode habilitar o filtro para visualizá-las rapidamente.',

                textAlign: TextAlign.center,

                style: const TextStyle(

                  color: Colors.orangeAccent,

                  fontSize: 12,

                ),

              ),

            ),

        ],

      ),

    );

  }

}



class _PurchaseSummaryRow extends StatelessWidget {

  const _PurchaseSummaryRow({

    required this.entries,

    required this.selectedKey,

    required this.onSelect,

  });



  final List<_PurchaseSummaryInfo> entries;

  final String selectedKey;

  final ValueChanged<String> onSelect;



  @override

  Widget build(BuildContext context) {

    return Wrap(

      spacing: 12,

      runSpacing: 12,

      children: entries.map((entry) {

        final selected = entry.key == selectedKey;

        return GestureDetector(

          onTap: () => onSelect(entry.key),

          child: AnimatedContainer(

            duration: const Duration(milliseconds: 200),

            width: 150,

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color: selected

                  ? entry.color.withValues(alpha: 0.2)

                  : context.themeSurface,

              borderRadius: BorderRadius.circular(16),

              border: Border.all(

                color:

                    selected

                        ? entry.color

                        : context.themeBorder,

              ),

            ),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Icon(

                  entry.icon,

                  size: 20,

                  color: entry.color.withValues(alpha: 0.9),

                ),

                const SizedBox(height: 8),

                Text(

                  entry.label,

                  style: const TextStyle(

                    color: Colors.white70,

                    fontSize: 12,

                  ),

                ),

                const SizedBox(height: 4),

                Text(

                  entry.value,

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 18,

                    fontWeight: FontWeight.bold,

                  ),

                ),

                if (entry.subtitle != null) ...[

                  const SizedBox(height: 4),

                  Text(

                    entry.subtitle!,

                    style: const TextStyle(

                      color: Colors.white60,

                      fontSize: 12,

                    ),

                  ),

                ],

              ],

            ),

          ),

        );

      }).toList(),

    );

  }

}



class _PurchaseSummaryInfo {

  const _PurchaseSummaryInfo({

    required this.key,

    required this.label,

    required this.value,

    required this.color,

    required this.icon,

    this.subtitle,

  });



  final String key;

  final String label;

  final String value;

  final String? subtitle;

  final Color color;

  final IconData icon;

}



class _PurchaseCard extends StatelessWidget {

  const _PurchaseCard({

    required this.purchase,

    required this.controller,

    required this.onDetails,

    this.onReceive,

  });



  final PurchaseModel purchase;

  final PurchasesController controller;

  final VoidCallback? onReceive;

  final VoidCallback onDetails;



  Color _statusColor() {
    final status = purchase.status.toLowerCase();
    if (status == 'received') return Colors.greenAccent;
    if (status == 'canceled' || status == 'cancelled') {
      return Colors.redAccent;
    }
    if (status == 'submitted') return Colors.lightBlueAccent;
    if (status == 'approved') return Colors.tealAccent;
    if (status == 'ordered') return Colors.amberAccent;
    return Colors.white70;
  }



  @override

  Widget build(BuildContext context) {

    final supplier = controller.supplierNameFor(purchase.supplierId);

    final statusLabel = controller.statusLabel(purchase.status);

    final total = controller.totalFor(purchase);

    final subtotal = controller.subtotalFor(purchase);

    final freight = purchase.freight ?? 0;

    final createdAt = purchase.createdAt?.toLocal();

    final dueDate = purchase.paymentDueDate?.toLocal();

    final receivedAt = purchase.receivedAt?.toLocal();

    final now = DateTime.now();

    final startOfToday = DateTime(now.year, now.month, now.day);

    final isOverdue = dueDate != null && dueDate.isBefore(startOfToday);

    final alerts = purchase.alerts;

    final classifications = purchase.classifications;



    return Material(

      color: Colors.transparent,

      child: InkWell(

        borderRadius: BorderRadius.circular(18),

        onTap: onDetails,

        child: Ink(

          decoration: BoxDecoration(

            color: context.themeSurface,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: context.themeBorder),

            boxShadow: context.shadowCard,

          ),

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          supplier,

                          style: const TextStyle(

                            color: Colors.white,

                            fontSize: 16,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          'ID ${purchase.id}',

                          style: const TextStyle(color: Colors.white54),

                        ),

                      ],

                    ),

                  ),

                  _PurchaseInfoChip(

                    icon: Icons.flag_outlined,

                    label: 'Status',

                    value: statusLabel,

                    valueColor: _statusColor(),

                  ),

                ],

              ),

              const SizedBox(height: 12),

              Wrap(

                spacing: 12,

                runSpacing: 10,

                children: [

                  if (createdAt != null)

                    _PurchaseInfoChip(

                      icon: Icons.calendar_today_outlined,

                      label: 'Criada em',

                      value: _purchaseDateFormatter.format(createdAt),

                    ),

                  if (dueDate != null)

                    _PurchaseInfoChip(

                      icon: Icons.event_note_outlined,

                      label: 'Vencimento',

                      value: _purchaseDateFormatter.format(dueDate),

                      valueColor:

                          isOverdue ? Colors.orangeAccent : Colors.white,

                    ),

                  if (receivedAt != null)

                    _PurchaseInfoChip(

                      icon: Icons.download_done_outlined,

                      label: 'Recebida em',

                      value: _purchaseDateFormatter.format(receivedAt),

                    ),

                  _PurchaseInfoChip(

                    icon: Icons.inventory_2_outlined,

                    label: 'Itens',

                    value: '${purchase.items.length}',

                  ),

                  _PurchaseInfoChip(

                    icon: Icons.payments_outlined,

                    label: 'Subtotal',

                    value: _purchaseCurrencyFormatter.format(subtotal),

                  ),

                  if (freight > 0)

                    _PurchaseInfoChip(

                      icon: Icons.local_shipping_outlined,

                      label: 'Frete',

                      value: _purchaseCurrencyFormatter.format(freight),

                    ),

                  _PurchaseInfoChip(

                    icon: Icons.attach_money,

                    label: 'Total',

                    value: _purchaseCurrencyFormatter.format(total),

                    valueColor: Colors.greenAccent,

                  ),

                ],

              ),

              if (classifications.isNotEmpty) ...[

                const SizedBox(height: 12),

                const Text(

                  'Categorias desta compra',

                  style: TextStyle(

                    color: Colors.white70,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 6),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: classifications.take(4).map((classification) {
                    return Chip(
                      backgroundColor: Colors.white10,
                      label: Text(
                        '${classification.categoryName.isEmpty ? 'Sem categoria' : classification.categoryName} · ${_purchaseCurrencyFormatter.format(classification.total)}',
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (alerts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Alertas',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                Column(

                  children: alerts.take(2).map((alert) {

                    return Padding(

                      padding: const EdgeInsets.only(bottom: 6),

                      child: _PurchaseAlertChip(alert: alert),

                    );

                  }).toList(),

                ),

                if (alerts.length > 2)

                  Align(

                    alignment: Alignment.centerRight,

                    child: TextButton(

                      onPressed: onDetails,

                      child: Text('Ver todos (${alerts.length})'),

                    ),

                  ),

              ],

              const SizedBox(height: 12),

              Row(

                children: [

                  if (onReceive != null) ...[

                    Expanded(

                      child: ElevatedButton.icon(

                        style: ElevatedButton.styleFrom(

                          backgroundColor: context.themeGreen,

                          foregroundColor: Colors.white,

                        ),

                        onPressed: onReceive,

                        icon: const Icon(Icons.download_done_outlined),

                        label: const Text('Marcar recebida'),

                      ),

                    ),

                    const SizedBox(width: 12),

                  ],

                  Expanded(

                    child: OutlinedButton.icon(

                      style: OutlinedButton.styleFrom(

                        foregroundColor: Colors.white,

                        side: BorderSide(color: context.themeBorder),

                      ),

                      onPressed: onDetails,

                      icon: const Icon(Icons.visibility_outlined),

                      label: const Text('Detalhes'),

                    ),

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _PurchaseInfoChip extends StatelessWidget {

  const _PurchaseInfoChip({

    required this.icon,

    required this.label,

    required this.value,

    this.valueColor,

  });



  final IconData icon;

  final String label;

  final String value;

  final Color? valueColor;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.04),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white12),

      ),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(icon, size: 16, color: Colors.white60),

          const SizedBox(width: 6),

          Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                label,

                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),

              Text(

                value,

                style: TextStyle(

                  color: valueColor ?? Colors.white,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }

}



class _PurchaseAlertChip extends StatelessWidget {
  const _PurchaseAlertChip({required this.alert});

  final PurchaseAlertModel alert;

  @override

  Widget build(BuildContext context) {

    final delta = alert.deltaPercent;
    final double deltaValue = delta ?? 0;
    final bool isAbove = deltaValue > 0;
    final String deltaLabel =
        delta == null
            ? ''
            : "${deltaValue >= 0 ? '+' : ''}${deltaValue.toStringAsFixed(1)}%";


    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: isAbove

            ? Colors.redAccent.withValues(alpha: 0.15)

            : Colors.blueAccent.withValues(alpha: 0.15),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(

          color: isAbove ? Colors.redAccent : Colors.blueAccent,

        ),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Icon(

                isAbove ? Icons.trending_up : Icons.trending_down,

                color: Colors.white,

                size: 18,

              ),

              const SizedBox(width: 6),

              Expanded(

                child: Text(

                  alert.message,

                  style: const TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ),

              if (delta != null)

                Text(

                  deltaLabel,

                  style: const TextStyle(color: Colors.white70),

                ),

            ],

          ),

          if (alert.itemId != null && alert.itemId!.isNotEmpty)

            Padding(

              padding: const EdgeInsets.only(top: 4),

              child: Text(

                'Item: ${alert.itemId}',

                style: const TextStyle(color: Colors.white54, fontSize: 12),

              ),

            ),

        ],

      ),
    );
  }
}

class _PurchaseAlertCard extends StatelessWidget {
  const _PurchaseAlertCard({required this.alert});

  final PurchaseAlertModel alert;

  @override
  Widget build(BuildContext context) {
    final delta = alert.deltaPercent;
    final bool isAbove = (delta ?? 0) >= 0;
    final Color baseColor = isAbove ? Colors.redAccent : Colors.blueAccent;
    final List<String> subtitle = [];
    if ((alert.itemId ?? '').isNotEmpty) {
      subtitle.add('Item: ${alert.itemId}');
    }
    if (delta != null) {
      subtitle.add('Variação: ${delta.toStringAsFixed(1)}%');
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAbove ? Icons.trending_up : Icons.trending_down,
            color: baseColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle.join(' · '),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _PurchaseCategoriesSummary extends StatelessWidget {
  final List<PurchaseClassificationModel> classifications;
  final NumberFormat currency;

  const _PurchaseCategoriesSummary({
    required this.classifications,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final items = classifications.isEmpty
        ? const [
            PurchaseClassificationModel(
              categoryId: '',
              categoryName: 'Sem categoria',
              total: 0,
            ),
          ]
        : classifications;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorias desta compra',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.categoryName.isEmpty
                          ? 'Sem categoria'
                          : item.categoryName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Text(
                    currency.format(item.total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseAlertsSummary extends StatelessWidget {
  const _PurchaseAlertsSummary({
    required this.totalAlerts,
    required this.purchaseCount,
    required this.onTap,
  });

  final int totalAlerts;
  final int purchaseCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text =
        purchaseCount == 1
            ? '$totalAlerts alerta detectado em 1 compra'
            : '$totalAlerts alertas em $purchaseCount compras';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _PurchaseHistoryTimeline extends StatelessWidget {
  const _PurchaseHistoryTimeline({required this.entries});

  final List<PurchaseHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sorted = entries.toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return Column(
      children: sorted.map((entry) {
        final dateText = entry.createdAt != null
            ? _purchaseDateFormatter.format(entry.createdAt!.toLocal())
            : 'Data nao informada';
        final user =
            (entry.userName ?? entry.userId ?? '').isEmpty
                ? null
                : (entry.userName ?? entry.userId);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 12, color: Colors.white54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      dateText,
                      style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
                    ),
                    if (user != null)
                      Text(
                        'Por $user',
                        style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
                      ),
                    if ((entry.notes ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entry.notes!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}













