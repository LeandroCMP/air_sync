import 'package:air_sync/application/auth/auth_service_application.dart';

import 'package:air_sync/application/ui/input_formatters.dart';

import 'package:air_sync/application/ui/theme_extensions.dart';

import 'package:air_sync/application/ui/widgets/ai_loading_overlay.dart';

import 'package:air_sync/models/create_order_purchase_dto.dart';

import 'package:air_sync/models/inventory_model.dart';

import 'package:air_sync/models/order_costs_model.dart';

import 'package:air_sync/models/order_model.dart';

import 'package:air_sync/models/supplier_model.dart';

import 'package:air_sync/modules/orders/order_pdf_viewer_page.dart';

import 'package:air_sync/modules/orders/widgets/order_finish_sheet.dart';

import 'package:air_sync/modules/orders/widgets/order_update_sheet.dart';

import 'package:air_sync/repositories/suppliers/suppliers_repository.dart';

import 'package:air_sync/repositories/suppliers/suppliers_repository_impl.dart';

import 'package:air_sync/services/suppliers/suppliers_service.dart';

import 'package:air_sync/services/suppliers/suppliers_service_impl.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:intl/intl.dart';



import './order_detail_controller.dart';



final NumberFormat _orderCurrencyFormatter =

    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');



class OrderDetailPage extends GetView<OrderDetailController> {

  const OrderDetailPage({super.key});



  @override

  Widget build(BuildContext context) {

    final authService = Get.find<AuthServiceApplication>();

    return Scaffold(

      appBar: AppBar(

        title: const Text('Detalhes da OS'),

        actions: [

          IconButton(

            icon: const Icon(Icons.picture_as_pdf_outlined),

            onPressed: () => _openPdf(controller),

          ),

        ],

      ),

      body: Obx(() {

        final user = authService.user.value;

        final canUseInsights = user?.hasPermission('orders.read') ?? false;

        final canCreatePurchase = user?.hasPermission('orders.write') ?? false;

        final order = controller.order.value;

        return AnimatedSwitcher(

          duration: const Duration(milliseconds: 250),

          child:

              order == null

                  ? const Center(

                    key: ValueKey('loading-state'),

                    child: CircularProgressIndicator(),

                  )

                  : Builder(

                    key: ValueKey('order-${order.id}'),

                    builder: (context) {

                      final timeline = _buildTimeline(order);

                      return RefreshIndicator(

                        onRefresh: controller.load,

                        child: ListView(

                          padding: const EdgeInsets.all(16),

                          children: [

                            _Header(order: order),

                            const SizedBox(height: 16),

                            if (canUseInsights) ...[

                              _OrderInsightsPanel(controller: controller),

                              const SizedBox(height: 16),

                            ],

                            _CostSummarySection(

                              controller: controller,

                              order: order,

                            ),

                            const SizedBox(height: 20),

                            _SectionTitle('Checklist'),

                            if (order.checklist.isEmpty)

                              const Text(

                                'Sem itens cadastrados.',

                                style: TextStyle(color: Colors.white54),

                              )

                            else

                              ...order.checklist.map(

                                (item) => ListTile(

                                  contentPadding: EdgeInsets.zero,

                                  leading: Icon(

                                    item.done

                                        ? Icons.check_circle

                                        : Icons.radio_button_off,

                                    color:

                                        item.done

                                            ? context.themeGreen

                                            : Colors.white38,

                                  ),

                                  title: Text(

                                    item.item,

                                    style: const TextStyle(color: Colors.white),

                                  ),

                                  subtitle:

                                      item.note == null

                                          ? null

                                          : Text(

                                            item.note!,

                                            style: const TextStyle(

                                              color: Colors.white70,

                                            ),

                                          ),

                                ),

                              ),

                            const SizedBox(height: 20),

                            _SectionTitle('Materiais'),

                            if (order.materials.isNotEmpty) ...[

                              _MaterialsSummaryCard(order: order),

                              const SizedBox(height: 8),

                              if (canCreatePurchase)

                                Align(

                                  alignment: Alignment.centerLeft,

                                  child: ElevatedButton.icon(

                                    onPressed: () => _openPurchaseFromOrderSheet(

                                      context,

                                      controller,

                                      order,

                                    ),

                                    icon: const Icon(Icons.shopping_cart_checkout_outlined),

                                    label: const Text('Gerar compra para reposio'),

                                  ),

                                ),

                            ],

                            if (order.materials.isEmpty)

                              const Text(

                                'Nenhum material vinculado.',

                                style: TextStyle(color: Colors.white54),

                              )

                            else

                              ...order.materials.map(

                                (material) => _MaterialTile(

                                  material: material,

                                  onReserve:

                                      material.itemId.isEmpty

                                          ? null

                                          : () => _handleMaterialAdjustment(

                                            context,

                                            controller,

                                            material,

                                            reserve: true,

                                          ),

                                  onDeduct:

                                      material.itemId.isEmpty

                                          ? null

                                          : () => _handleMaterialAdjustment(

                                            context,

                                            controller,

                                            material,

                                            reserve: false,

                                          ),

                                ),

                              ),

                            const SizedBox(height: 20),

                            _SectionTitle('Cobrana'),

                            if (order.billing.items.isEmpty)

                              const Text(

                                'Sem itens de cobrançaa.',

                                style: TextStyle(color: Colors.white54),

                              )

                            else

                              Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  ...order.billing.items.map(

                                    (item) => ListTile(

                                      contentPadding: EdgeInsets.zero,

                                      title: Text(

                                        item.name,

                                        style: const TextStyle(

                                          color: Colors.white,

                                        ),

                                      ),

                                      subtitle: Text(

                                        '${item.type == 'service' ? 'Serviço' : 'Peça'} ? ${item.qty} x R\$ ${item.unitPrice.toStringAsFixed(2)}',

                                        style: const TextStyle(

                                          color: Colors.white70,

                                        ),

                                      ),

                                      trailing: Text(

                                        'R\$ ${item.lineTotal.toStringAsFixed(2)}',

                                        style: const TextStyle(

                                          color: Colors.white,

                                        ),

                                      ),

                                    ),

                                  ),

                                  const Divider(),

                                  _BillingSummary(order.billing),

                                ],

                              ),

                            const SizedBox(height: 24),

                            if (timeline.isNotEmpty) ...[

                              _SectionTitle('Linha do tempo'),

                              Card(

                                color: context.themeSurface,

                                shape: RoundedRectangleBorder(

                                  borderRadius: BorderRadius.circular(16),

                                ),

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(

                                    horizontal: 12,

                                    vertical: 8,

                                  ),

                                  child: _Timeline(events: timeline),

                                ),

                              ),

                              const SizedBox(height: 24),

                            ],

                            _Actions(controller: controller, order: order),

                          ],

                        ),

                      );

                    },

                  ),

        );

      }),

    );

  }



  Future<void> _openPdf(OrderDetailController controller) async {

    final pdfData = await controller.preparePdfData();

    if (pdfData == null) return;

    await Get.to(

      () => OrderPdfViewerPage(

        order: pdfData.order,

        client: pdfData.client,

        location: pdfData.location,

        equipment: pdfData.equipment,

        technicians: pdfData.technicians,

        materialCatalog: pdfData.materialCatalog,

      ),

    );

  }

}



class _Header extends StatelessWidget {

  const _Header({required this.order});



  final OrderModel order;



  @override

  Widget build(BuildContext context) {

    final status = _statusFor(order.status);

    return Card(

      color: context.themeDark,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                CircleAvatar(

                  backgroundColor: status.color.withValues(alpha: 0.15),

                  foregroundColor: status.color,

                  child: Icon(status.icon),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        order.clientName ?? 'Cliente não informado',

                        style: const TextStyle(

                          color: Colors.white,

                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                      Text(

                        status.label,

                        style: TextStyle(

                          color: status.color,

                          fontWeight: FontWeight.w500,

                        ),

                      ),

                    ],

                  ),

                ),

              ],

            ),

            const SizedBox(height: 12),

            _InfoRow('Local', order.locationLabel),

            _InfoRow('Equipamento', order.equipmentLabel),

            _InfoRow('Agendada para', _formatDateTime(order.scheduledAt)),

            _InfoRow('Incio', _formatDateTime(order.startedAt)),

            _InfoRow('Concluso', _formatDateTime(order.finishedAt)),

            if (order.notes != null && order.notes!.isNotEmpty)

              _InfoRow('Observaes', order.notes),

          ],

        ),

      ),

    );

  }

}



class _InfoRow extends StatelessWidget {

  const _InfoRow(this.label, this.value);



  final String label;

  final String? value;



  @override

  Widget build(BuildContext context) {

    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();

    return Padding(

      padding: const EdgeInsets.only(top: 6),

      child: RichText(

        text: TextSpan(

          style: const TextStyle(color: Colors.white70),

          children: [

            TextSpan(

              text: '$label: ',

              style: const TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.w600,

              ),

            ),

            TextSpan(text: value),

          ],

        ),

      ),

    );

  }

}



class _BillingSummary extends StatelessWidget {

  const _BillingSummary(this.billing);



  final OrderBilling billing;



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        _summaryRow('Subtotal', billing.subtotal),

        _summaryRow('Desconto', -billing.discount),

        const SizedBox(height: 6),

        _summaryRow('Total', billing.total, emphasize: true),

      ],

    );

  }



  Widget _summaryRow(String label, num value, {bool emphasize = false}) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        Text(

          label,

          style: TextStyle(

            color: Colors.white70,

            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,

          ),

        ),

        Text(

          'R\$ ${value.toStringAsFixed(2)}',

          style: TextStyle(

            color: Colors.white,

            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,

          ),

        ),

      ],

    );

  }

}



class _Actions extends StatelessWidget {

  const _Actions({required this.controller, required this.order});



  final OrderDetailController controller;

  final OrderModel order;



  @override

  Widget build(BuildContext context) {

    final canStart =

        (order.isScheduled || order.isDraft) &&

        !order.isInProgress &&

        !order.isDone &&

        !order.isCanceled;

    final canFinish = !order.isDone && !order.isCanceled;

    final canEdit = !order.isDone && !order.isCanceled;



    final buttons = <Widget>[];



    void addButton(Widget widget) {

      buttons.add(widget);

    }



    if (canStart) {

      addButton(

        ElevatedButton.icon(

          icon: const Icon(Icons.play_arrow),

          label: const Text('Iniciar OS'),

          onPressed: controller.startOrder,

        ),

      );

    }



    if (canEdit) {

      addButton(

        ElevatedButton.icon(

          icon: const Icon(Icons.edit_outlined),

          label: const Text('Atualizar OS'),

          onPressed: () => _handleUpdate(context),

        ),

      );

      addButton(

        ElevatedButton.icon(

          icon: const Icon(Icons.event),

          label: const Text('Reagendar OS'),

          onPressed: () => _handleReschedule(context),

        ),

      );

    }



    if (canFinish) {

      addButton(

        ElevatedButton.icon(

          icon: const Icon(Icons.check_circle_outline),

          label: const Text('Finalizar OS'),

          onPressed: () => _handleFinish(context),

        ),

      );

    }



    final maxWidth = MediaQuery.sizeOf(context).width;

    final isWide = maxWidth > 520;

    final buttonWidth = isWide ? (maxWidth / 2) - 12 : maxWidth;

    return Wrap(

      spacing: 12,

      runSpacing: 12,

      children:

          buttons

              .map((button) => SizedBox(width: buttonWidth, child: button))

              .toList(),

    );

  }



  Future<void> _handleFinish(BuildContext context) async {

    OrderModel? currentOrder = controller.order.value;

    if (currentOrder == null) return;



    final hasPendingChecklist = currentOrder.checklist.any(

      (item) => item.done != true,

    );

    if (hasPendingChecklist) {

      final resolved = await _showChecklistResolver(context);

      if (!resolved) return;

      currentOrder = controller.order.value;

      if (currentOrder == null) return;

    }



    var inventoryItems = await controller.fetchInventoryItems();

    if (inventoryItems.isEmpty && currentOrder.materials.isNotEmpty) {

      inventoryItems = _materialsAsInventory(currentOrder.materials);

    }

    if (inventoryItems.isEmpty) {

      Get.snackbar(

        'Estoque',

        'Nenhum item de estoque disponvel para vincular.',

        snackPosition: SnackPosition.BOTTOM,

      );

      return;

    }

    if (controller.serviceTypes.isEmpty) {

      await controller.refreshServiceTypes();

    }
    final serviceTypes = controller.serviceTypes.toList();

    final companyProfile = await controller.fetchCompanyProfile();

    if (!context.mounted) return;

    final result = await showOrderFinishSheet(

      context: context,

      order: currentOrder,

      inventoryItems: inventoryItems,
      serviceTypes: serviceTypes,
      companyProfile: companyProfile,

    );

    if (result == null) return;

    var payments = result.payments;

    if (payments.isEmpty) {

      payments = [

        OrderPaymentInput(

          method: 'PIX',

          amount: result.totalDue > 0 ? result.totalDue : 0,

        ),

      ];

    }

    final finished = await controller.finishOrder(

      billingItems: result.billingItems,

      discount: result.discount ?? 0,

      signatureBase64: result.signatureBase64,

      notes: result.notes,

      payments: payments,

    );

    if (!finished) return;

    if (result.materialInputs.isNotEmpty) {

      await controller.deductMaterials(result.materialInputs);

    }

  }



  Future<bool> _showChecklistResolver(BuildContext context) async {

    final currentOrder = controller.order.value;

    if (currentOrder == null || currentOrder.checklist.isEmpty) {

      return true;

    }

    final toggles = currentOrder.checklist

        .map(

          (item) => _ChecklistToggle(

            label: item.item,

            done: item.done,

          ),

        )

        .toList();



    final confirmed = await showModalBottomSheet<bool>(

      context: context,

      isScrollControlled: true,

      backgroundColor: context.themeDark,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (ctx) => StatefulBuilder(

        builder: (ctx, setState) => Padding(

          padding: EdgeInsets.only(

            left: 20,

            right: 20,

            top: 20,

            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                children: [

                  const Expanded(

                    child: Text(

                      'Checklist da OS',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 18,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                  IconButton(

                    onPressed: () => Navigator.of(ctx).pop(false),

                    icon: const Icon(Icons.close, color: Colors.white54),

                  ),

                ],

              ),

              const SizedBox(height: 8),

              Align(

                alignment: Alignment.centerLeft,

                child: Text(

                  'Marque os itens concludos para liberar a finalizao.',

                  style: TextStyle(color: context.themeTextSubtle),

                ),

              ),

              const SizedBox(height: 12),

              ...toggles.map(

                (item) => CheckboxListTile(

                  value: item.done,

                  onChanged: (value) {

                    setState(() => item.done = value ?? false);

                  },

                  dense: true,

                  title: Text(item.label),

                  controlAffinity: ListTileControlAffinity.leading,

                ),

              ),

              Row(

                children: [

                  TextButton.icon(

                    onPressed: () {

                      setState(() {

                        final shouldCheckAll =

                            toggles.any((element) => !element.done);

                        for (final toggle in toggles) {

                          toggle.done = shouldCheckAll;

                        }

                      });

                    },

                    icon: const Icon(Icons.done_all),

                    label: const Text('Marcar todos'),

                  ),

                  const Spacer(),

                  TextButton(

                    onPressed: () => Navigator.of(ctx).pop(false),

                    child: const Text('Cancelar'),

                  ),

                  const SizedBox(width: 8),

                  ElevatedButton(

                    onPressed: () {

                      if (toggles.any((element) => !element.done)) {

                        Get.snackbar(

                          'Checklist',

                          'Marque todos os itens como concludos antes de finalizar.',

                          snackPosition: SnackPosition.BOTTOM,

                        );

                        return;

                      }

                      Navigator.of(ctx).pop(true);

                    },

                    child: const Text('Salvar checklist'),

                  ),

                ],

              ),

            ],

          ),

        ),

      ),

    );



    if (confirmed != true) return false;



    final inputs =

        toggles

            .map(

              (item) => OrderChecklistInput(

                item: item.label,

                done: item.done,

              ),

            )

            .toList();

    await controller.updateOrder(checklist: inputs);

    return true;

  }



  Future<void> _handleUpdate(BuildContext context) async {
    final technicians = await controller.fetchTechnicians();
    if (!context.mounted) return;

    final result = await showOrderUpdateSheet(
      context: context,
      order: order,
      technicians: technicians,
    );

    if (result == null) return;

    final ok = await controller.updateOrder(
      status: result.status,
      scheduledAt: result.scheduledAt,
      technicianIds: result.technicianIds,
      notes: result.notes,
    );

    if (!context.mounted) return;

    if (!ok && controller.bookingConflict.value != null) {
      await _showBookingConflictDialog(context);
    }
  }

  Future<void> _handleReschedule(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = order.scheduledAt ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (date == null) return;
    if (!context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final ok = await controller.rescheduleOrder(scheduledAt: scheduled);
    if (!context.mounted) return;
    if (!ok && controller.bookingConflict.value != null) {
      await _showBookingConflictDialog(context);
    }
  }

  Future<void> _showBookingConflictDialog(BuildContext context) async {
    final conflict = controller.bookingConflict.value;
    if (conflict == null) return;

    final technicians = await controller.fetchTechnicians();
    final techNames = technicians
        .where((tech) => conflict.technicianIds.contains(tech.id))
        .map((tech) => tech.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    final base = conflict.message.isNotEmpty
        ? conflict.message
        : 'Este tecnico ja tem OS nesse horario.';
    final detail =
        techNames.isEmpty ? '' : '\\nTecnicos: ${techNames.join(', ')}';

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conflito de agenda'),
        content: Text('$base\\nAjuste o horario ou troque o tecnico.$detail'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleReschedule(context);
            },
            child: const Text('Alterar horario'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleUpdate(context);
            },
            child: const Text('Trocar tecnico'),
          ),
        ],
      ),
    );
  }

}

List<InventoryItemModel> _materialsAsInventory(

  List<OrderMaterialItem> materials,

) {

  return materials

      .where((m) => m.itemId.isNotEmpty)

      .map(

        (m) => InventoryItemModel.fromMap(m.itemId, {

          'id': m.itemId,

          'name': m.description ?? m.itemName ?? 'Item ${m.itemId}',

          'description': m.description ?? m.itemName ?? 'Item ${m.itemId}',

          'sku': m.itemId,

          'unit': 'UN',

          'onHand': m.qty,

          'minQty': 0,

          'active': true,

          'sellPrice': m.unitPrice ?? m.unitCost ?? 0,

          'avgCost': m.unitCost ?? m.unitPrice ?? 0,

          'lastPurchaseCost': m.unitCost ?? m.unitPrice ?? 0,

        }),

      )

      .toList();

}



Future<void> _handleMaterialAdjustment(

  BuildContext context,

  OrderDetailController controller,

  OrderMaterialItem material, {

  required bool reserve,

}) async {

  final qtyCtrl = TextEditingController(text: material.qty.toString());

  final result = await showDialog<double>(

    context: context,

    builder: (ctx) {

      return AlertDialog(

        title: Text(reserve ? 'Reservar estoque' : 'Baixar estoque'),

        content: TextField(

          controller: qtyCtrl,

          decoration: const InputDecoration(labelText: 'Quantidade'),

          keyboardType: TextInputType.numberWithOptions(decimal: true),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.of(ctx).pop(),

            child: const Text('Cancelar'),

          ),

          ElevatedButton(

            onPressed: () {

              final value = double.tryParse(qtyCtrl.text.replaceAll(',', '.'));

              Navigator.of(ctx).pop(value);

            },

            child: const Text('Confirmar'),

          ),

        ],

      );

    },

  );

  if (result == null || result <= 0) return;

  String resolveLabel(String? source, String fallback) {

    final text = source?.trim() ?? '';

    return text.isEmpty ? fallback : text;

  }



  final resolvedName =

      resolveLabel(material.itemName, resolveLabel(material.description, material.itemId));

  final resolvedDescription =

      resolveLabel(material.description, resolveLabel(material.itemName, material.itemId));



  final input = OrderMaterialInput(

    itemId: material.itemId,

    qty: result,

    itemName: resolvedName,

    description: resolvedDescription,

    unitPrice: material.unitPrice,

    unitCost: material.unitCost,

  );

  if (reserve) {

    await controller.reserveMaterials([input]);

  } else {

    await controller.deductMaterials([input]);

  }

}



class _MaterialTile extends StatelessWidget {

  const _MaterialTile({required this.material, this.onReserve, this.onDeduct});



  final OrderMaterialItem material;

  final VoidCallback? onReserve;

  final VoidCallback? onDeduct;



  @override

  Widget build(BuildContext context) {

    final title =

        material.itemName?.trim().isNotEmpty == true

            ? material.itemName!

            : material.itemId;

    final subtitle =

        material.description?.trim().isNotEmpty == true

            ? material.description!

            : null;

    final hasUnitCost = material.unitCost != null;

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final lineCost = hasUnitCost ? currency.format(material.lineCost) : null;

    final unitCost = hasUnitCost ? currency.format(material.unitCost) : null;

    return Card(

      color: context.themeDark,

      margin: const EdgeInsets.only(bottom: 8),

      child: Padding(

        padding: const EdgeInsets.all(12),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Expanded(

                  child: Text(

                    title,

                    style: const TextStyle(

                      color: Colors.white,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                ),

                if (material.itemId.isNotEmpty &&

                    (onReserve != null || onDeduct != null))

                  PopupMenuButton<String>(

                    onSelected: (value) {

                      if (value == 'reserve') {

                        onReserve?.call();

                      } else if (value == 'deduct') {

                        onDeduct?.call();

                      }

                    },

                    itemBuilder:

                        (_) => const [

                          PopupMenuItem(

                            value: 'reserve',

                            child: Text('Reservar'),

                          ),

                          PopupMenuItem(

                            value: 'deduct',

                            child: Text('Baixar estoque'),

                          ),

                        ],

                  ),

              ],

            ),

            if (subtitle != null) ...[

              const SizedBox(height: 4),

              Text(subtitle, style: const TextStyle(color: Colors.white70)),

            ],

            const SizedBox(height: 4),

            Text(

              'Qtd: ${material.qty} ? Reservado: ${material.reserved ? 'Sim' : 'No'}',

              style: const TextStyle(color: Colors.white60),

            ),

            if (hasUnitCost) ...[

              const SizedBox(height: 4),

              Text(

                'Custo unitrio: $unitCost',

                style: const TextStyle(color: Colors.white60),

              ),

              Text(

                'Total em custo: $lineCost',

                style: const TextStyle(

                  color: Colors.white,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ],

        ),

      ),

    );

  }

}



class _MaterialsSummaryCard extends StatelessWidget {

  const _MaterialsSummaryCard({required this.order});



  final OrderModel order;



  @override

  Widget build(BuildContext context) {

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final materialCost = order.materialsCostTotal;

    final revenue = order.billing.total.toDouble();

    final margin = order.estimatedMargin;

    final marginPercent =

        revenue == 0 ? null : ((margin / revenue) * 100).toDouble();

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: context.themeDark,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white12),

      ),

      child: Row(

        children: [

          Expanded(

            child: _SummaryColumn(

              label: 'Custo materiais',

              value: currency.format(materialCost),

            ),

          ),

          Container(

            width: 1,

            height: 40,

            margin: const EdgeInsets.symmetric(horizontal: 12),

            color: Colors.white10,

          ),

          Expanded(

            child: _SummaryColumn(

              label: 'Faturamento',

              value: currency.format(revenue),

            ),

          ),

          Container(

            width: 1,

            height: 40,

            margin: const EdgeInsets.symmetric(horizontal: 12),

            color: Colors.white10,

          ),

          Expanded(

            child: _SummaryColumn(

              label: 'Margem estimada',

              value: currency.format(margin),

              helper:

                  marginPercent == null

                      ? null

                      : '${marginPercent.toStringAsFixed(1)}%',

            ),

          ),

        ],

      ),

    );

  }

}



class _SummaryColumn extends StatelessWidget {

  const _SummaryColumn({required this.label, required this.value, this.helper});



  final String label;

  final String value;

  final String? helper;



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style: const TextStyle(color: Colors.white54, fontSize: 12),

        ),

        const SizedBox(height: 4),

        Text(

          value,

          style: const TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.bold,

            fontSize: 16,

          ),

        ),

        if (helper != null)

          Text(

            helper!,

            style: const TextStyle(color: Colors.white60, fontSize: 12),

          ),

      ],

    );

  }

}



class _Timeline extends StatelessWidget {

  const _Timeline({required this.events});



  final List<_TimelineEvent> events;



  @override

  Widget build(BuildContext context) {

    return Column(

      children:

          events.asMap().entries.map((entry) {

            final index = entry.key;

            final event = entry.value;

            return Container(

              margin: EdgeInsets.only(

                bottom: index == events.length - 1 ? 0 : 12,

              ),

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(

                color: Colors.white.withValues(alpha: 0.03),

                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),

              ),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  CircleAvatar(

                    backgroundColor: event.color.withValues(alpha: 0.18),

                    child: Icon(event.icon, color: event.color),

                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          event.label,

                          style: const TextStyle(

                            color: Colors.white,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          event.description,

                          style: const TextStyle(color: Colors.white70),

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



class _TimelineEvent {

  _TimelineEvent({

    required this.label,

    required this.date,

    required this.icon,

    required this.color,

  });



  final String label;

  final DateTime date;

  final IconData icon;

  final Color color;



  String get description {

    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return formatter.format(date.toLocal());

  }

}



List<_TimelineEvent> _buildTimeline(OrderModel order) {

  final events = <_TimelineEvent>[];

  if (order.createdAt != null) {

    events.add(

      _TimelineEvent(

        label: 'Criada',

        date: order.createdAt!,

        icon: Icons.fiber_manual_record,

        color: Colors.white70,

      ),

    );

  }

  if (order.scheduledAt != null) {

    events.add(

      _TimelineEvent(

        label: 'Agendada',

        date: order.scheduledAt!,

        icon: Icons.event,

        color: Colors.lightBlueAccent,

      ),

    );

  }

  if (order.startedAt != null) {

    events.add(

      _TimelineEvent(

        label: 'Iniciada',

        date: order.startedAt!,

        icon: Icons.play_arrow,

        color: Colors.orangeAccent,

      ),

    );

  }

  if (order.finishedAt != null) {

    events.add(

      _TimelineEvent(

        label: 'Concluda',

        date: order.finishedAt!,

        icon: Icons.check_circle,

        color: Colors.greenAccent,

      ),

    );

  }

  if (order.updatedAt != null) {

    events.add(

      _TimelineEvent(

        label: 'Atualizada',

        date: order.updatedAt!,

        icon: Icons.update,

        color: Colors.purpleAccent,

      ),

    );

  }

  return events;

}



String? _formatDateTime(DateTime? date) {

  if (date == null) return null;

  return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

}



_StatusItem _statusFor(String value) {

  if (value == 'scheduled') {

    return const _StatusItem(

      label: 'Agendada',

      color: Colors.blueAccent,

      icon: Icons.event_available,

    );

  }

  if (value == 'in_progress') {

    return const _StatusItem(

      label: 'Em andamento',

      color: Colors.orange,

      icon: Icons.build,

    );

  }

  if (value == 'done') {

    return const _StatusItem(

      label: 'Concluda',

      color: Colors.green,

      icon: Icons.check_circle,

    );

  }

  if (value == 'canceled') {

    return const _StatusItem(

      label: 'Cancelada',

      color: Colors.redAccent,

      icon: Icons.cancel,

    );

  }

  return const _StatusItem(

    label: 'Indefinido',

    color: Colors.white54,

    icon: Icons.help_outline,

  );

}



class _CostSummarySection extends StatelessWidget {

  const _CostSummarySection({required this.controller, required this.order});



  final OrderDetailController controller;

  final OrderModel order;



  @override

  Widget build(BuildContext context) {

    return Obx(() {

      final summary = controller.costSummary.value;

      final loading = controller.costSummaryLoading.value;

      final error = controller.costSummaryError.value;

      final revenue = summary?.revenue ?? order.billing.total.toDouble();

      final totalCost = summary?.totalCost ?? summary?.materialsCost ??

          order.materialsCostTotal;

      final marginValue =

          summary?.marginValue ?? (revenue - (totalCost));

      final marginPercent =

          summary?.marginPercent ??

          (revenue <= 0 ? 0 : (marginValue / revenue) * 100);

      final blocks = summary?.resolvedBlocks ?? const <OrderCostMetric>[];



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

                  'Custos e margem',

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const Spacer(),

                IconButton(

                  tooltip: 'Atualizar custos',

                  onPressed:

                      loading ? null : () => controller.refreshCostSummary(),

                  icon:

                      loading

                          ? const SizedBox(

                            width: 18,

                            height: 18,

                            child: CircularProgressIndicator(strokeWidth: 2),

                          )

                          : const Icon(Icons.refresh),

                ),

              ],

            ),

            const SizedBox(height: 8),

            if (error != null) ...[

              const SizedBox(height: 12),

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(

                  color: Colors.orange.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(error, style: const TextStyle(color: Colors.white70)),

                    Align(

                      alignment: Alignment.centerRight,

                      child: TextButton.icon(

                        onPressed: loading

                            ? null

                            : () => controller.refreshCostSummary(),

                        icon: const Icon(Icons.refresh),

                        label: const Text('Tentar novamente'),

                      ),

                    ),

                  ],

                ),

              ),

            ] else if (!loading && summary == null) ...[

              const SizedBox(height: 12),

              Text(

                'Ainda no recebemos o detalhamento financeiro desta OS.',

                style: TextStyle(color: context.themeTextSubtle),

              ),

            ],

            if (blocks.isNotEmpty) ...[

              const SizedBox(height: 16),

              ...blocks.map(

                (block) => Padding(

                  padding: const EdgeInsets.only(bottom: 12),

                  child: _CostBlockBar(

                    block: block,

                    totalCost: summary?.totalCost ?? block.value,

                  ),

                ),

              ),

            ],

            const SizedBox(height: 8),

            Row(

              children: [

                Expanded(

                  child: _CostValueTile(

                    label: 'Receita bruta',

                    value: revenue,

                    highlight: context.themeGreen,

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: _CostValueTile(

                    label: 'Custo total',

                    value: totalCost,

                    highlight: Colors.orangeAccent,

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: _CostValueTile(

                    label: 'Margem',

                    value: marginValue,

                    trailing: summary == null && marginPercent == 0

                        ? null

                        : _formatPercent(marginPercent),

                    highlight:

                        marginValue >= 0

                            ? context.themeGreen

                            : Colors.redAccent,

                  ),

                ),

              ],

            ),

            const SizedBox(height: 12),

            _MarginBar(

              revenue: revenue,

              totalCost: totalCost,

            ),

          ],

        ),

      );

    });

  }

}



class _OrderInsightsPanel extends StatelessWidget {

  const _OrderInsightsPanel({required this.controller});



  final OrderDetailController controller;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: context.themeDark,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.white12),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            'Assistentes inteligentes',

            style: TextStyle(

              color: Colors.white,

              fontSize: 16,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 8),

          Text(

            'Use os recursos de IA para apoiar o time técnico e preparar a comunicao com o cliente.',

            style: TextStyle(color: context.themeTextSubtle),

          ),

          const SizedBox(height: 12),

          Wrap(

            spacing: 12,

            runSpacing: 12,

            children: [

              OutlinedButton.icon(

                icon: const Icon(Icons.psychology_alt_outlined),

                label: const Text('Assistente técnico'),

                onPressed: () => _openOrderAssistantSheet(context, controller),

              ),

              OutlinedButton.icon(

                icon: const Icon(Icons.summarize_outlined),

                label: const Text('Resumo para cliente'),

                onPressed: () => _showOrderCustomerSummary(context, controller),

              ),

            ],

          ),

        ],

      ),

    );

  }

}



class _CostValueTile extends StatelessWidget {

  const _CostValueTile({

    required this.label,

    required this.value,

    this.trailing,

    this.highlight,

  });



  final String label;

  final double value;

  final String? trailing;

  final Color? highlight;



  @override

  Widget build(BuildContext context) {

    final color = highlight ?? Colors.white;

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

          Text(

            label,

            style: TextStyle(

              color: context.themeTextSubtle,

              fontSize: 12,

            ),

          ),

          const SizedBox(height: 6),

          Text(

            _formatCurrency(value),

            style: TextStyle(

              color: color,

              fontWeight: FontWeight.w700,

              fontSize: 16,

            ),

          ),

          if (trailing != null) ...[

            const SizedBox(height: 2),

            Text(

              trailing!,

              style: TextStyle(color: context.themeTextSubtle, fontSize: 12),

            ),

          ],

        ],

      ),

    );

  }

}



class _CostBlockBar extends StatelessWidget {

  const _CostBlockBar({required this.block, required this.totalCost});



  final OrderCostMetric block;

  final double totalCost;



  @override

  Widget build(BuildContext context) {

    final percent =

        block.percent ??

        (totalCost <= 0 ? null : (block.value / totalCost) * 100);

    final ratio =

        percent == null ? 0.0 : (percent / 100).clamp(0.0, 1.0).toDouble();

    final color = _costColorFor(block.code, context);

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            Expanded(

              child: Text(

                block.label,

                style: const TextStyle(

                  color: Colors.white,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ),

            Text(

              _formatCurrency(block.value),

              style: const TextStyle(color: Colors.white70),

            ),

          ],

        ),

        const SizedBox(height: 6),

        ClipRRect(

          borderRadius: BorderRadius.circular(6),

          child: LinearProgressIndicator(

            value: totalCost <= 0 ? 0 : ratio,

            minHeight: 6,

            backgroundColor: Colors.white12,

            valueColor: AlwaysStoppedAnimation(color),

          ),

        ),

        if (percent != null) ...[

          const SizedBox(height: 2),

          Text(

            '${_formatPercent(percent)} do custo',

            style: TextStyle(color: context.themeTextSubtle, fontSize: 12),

          ),

        ],

      ],

    );

  }

}



class _MarginBar extends StatelessWidget {

  const _MarginBar({required this.revenue, required this.totalCost});



  final double revenue;

  final double totalCost;



  @override

  Widget build(BuildContext context) {

    final ratio =

        revenue <= 0 ? 0.0 : (totalCost / revenue).clamp(0.0, 1.0).toDouble();

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            Text(

              'Proporo de custo',

              style: TextStyle(color: context.themeTextSubtle, fontSize: 12),

            ),

            const SizedBox(width: 8),

            Text(

              '${_formatPercent(ratio * 100)} do faturamento',

              style: const TextStyle(color: Colors.white70, fontSize: 12),

            ),

          ],

        ),

        const SizedBox(height: 4),

        ClipRRect(

          borderRadius: BorderRadius.circular(6),

          child: LinearProgressIndicator(

            value: ratio,

            minHeight: 8,

            backgroundColor: Colors.white12,

            valueColor: AlwaysStoppedAnimation(Colors.orangeAccent),

          ),

        ),

      ],

    );

  }

}



class _SectionTitle extends StatelessWidget {

  const _SectionTitle(this.title);



  final String title;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Text(

        title,

        style: const TextStyle(

          color: Colors.white,

          fontSize: 16,

          fontWeight: FontWeight.bold,

        ),

      ),

    );

  }

}



String _formatCurrency(num value) =>

    _orderCurrencyFormatter.format(value);



String _formatPercent(double value) {

  final absValue = value.abs();

  final decimals = absValue >= 100

      ? 0

      : absValue >= 10

      ? 1

      : 2;

  return '${value.toStringAsFixed(decimals)}%';

}



Color _costColorFor(String code, BuildContext context) {

  switch (code.toLowerCase()) {

    case 'materials':

    case 'material':

      return context.themePrimary;

    case 'purchases':

    case 'buying':

      return Colors.tealAccent;

    case 'overhead':

    case 'indirect':

      return Colors.purpleAccent;

    default:

      return Colors.lightBlueAccent;

  }

}



Future<void> _openOrderAssistantSheet(

  BuildContext context,

  OrderDetailController controller,

) async {

  final questionCtrl = TextEditingController();

  String? answer;

  bool submitting = false;



  await showModalBottomSheet(

    context: context,

    isScrollControlled: true,

    backgroundColor: context.themeDark,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

    ),

    builder: (ctx) {

      return StatefulBuilder(

        builder: (ctx, setState) {

          Future<void> submit() async {

            if (submitting) return;

            final question = questionCtrl.text.trim();

            if (question.isEmpty) return;

            setState(() => submitting = true);

            final hideOverlay = AiLoadingOverlay.show(

              ctx,

              message: 'Consultando assistente técnico...',

            );

            try {

              final result = await controller.fetchAssistantAnswer(question);

              if (!ctx.mounted) return;

              setState(() {

                submitting = false;

                answer = result;

              });

            } finally {

              hideOverlay();

            }

          }



          return Padding(

            padding: EdgeInsets.only(

              left: 20,

              right: 20,

              top: 20,

              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,

            ),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Row(

                  children: [

                    const Expanded(

                      child: Text(

                        'Assistente técnico',

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ),

                    IconButton(

                      onPressed: () => Navigator.of(ctx).pop(),

                      icon: const Icon(Icons.close, color: Colors.white54),

                    ),

                  ],

                ),

                const SizedBox(height: 8),

                TextField(

                  controller: questionCtrl,

                  maxLines: 3,

                  decoration: const InputDecoration(

                    labelText: 'Descreva a dvida do técnico',

                  ),

                ),

                const SizedBox(height: 12),

                SizedBox(

                  width: double.infinity,

                  child: ElevatedButton.icon(

                    icon: submitting

                        ? const SizedBox(

                          width: 18,

                          height: 18,

                          child: CircularProgressIndicator(strokeWidth: 2),

                        )

                        : const Icon(Icons.send_outlined),

                    label: Text(submitting ? 'Consultando...' : 'Perguntar'),

                    onPressed: submitting ? null : submit,

                  ),

                ),

                if ((answer ?? '').isNotEmpty) ...[

                  const SizedBox(height: 16),

                  const Text(

                    'Resposta',

                    style: TextStyle(

                      color: Colors.white70,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(

                      color: Colors.white.withValues(alpha: 0.05),

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: SelectableText(

                      answer!,

                      style: const TextStyle(color: Colors.white),

                    ),

                  ),

                ],

              ],

            ),

          );

        },

      );

    },

  ).whenComplete(questionCtrl.dispose);

}



Future<void> _showOrderCustomerSummary(

  BuildContext context,

  OrderDetailController controller,

) async {

  final hideOverlay = AiLoadingOverlay.show(

    context,

    message: 'Gerando resumo para o cliente...',

  );

  final summary = await controller.fetchCustomerSummary();

  hideOverlay();

  if (summary == null || !context.mounted) return;

  await showDialog(

    context: context,

    builder: (ctx) => AlertDialog(

      backgroundColor: context.themeDark,

      title: const Text('Resumo para o cliente'),

      content: SizedBox(

        width: double.maxFinite,

        child: SingleChildScrollView(

          child: SelectableText(summary),

        ),

      ),

      actions: [

        TextButton(

          onPressed: () => Navigator.of(ctx).pop(),

          child: const Text('Fechar'),

        ),

      ],

    ),

  );

}



Future<void> _openPurchaseFromOrderSheet(

  BuildContext context,

  OrderDetailController controller,

  OrderModel order,

) async {

  final materials = order.materials;

  if (materials.isEmpty) return;

  final freightCtrl = TextEditingController();

  final notesCtrl = TextEditingController();

  final drafts = materials

      .map(

        (material) => _OrderPurchaseItemForm(

          itemId: material.itemId,

          displayName:

              material.itemName ??

              material.description ??

              'Item ${material.itemId}',

          qty: material.qty.toDouble(),

          unitCost: material.unitCost ?? material.unitPrice,

          description: material.description ?? material.itemName,

          

        ),

      )

      .toList();

  DateTime? paymentDue;

  String? supplierId;

  String? supplierName;



  Future<void> pickSupplier(BuildContext ctx) async {

    try {

      final service = _ensureSuppliersService();

      final supplier = await _openSupplierPicker(ctx, service);

      if (supplier != null) {

        supplierId = supplier.id;

        supplierName = supplier.name;

      }

    } catch (e) {

      Get.showSnackbar(

        GetSnackBar(

          messageText: Text(

            'Falha ao carregar fornecedores: $e',

            style: const TextStyle(color: Colors.white),

          ),

          duration: const Duration(seconds: 3),

          backgroundColor: Colors.redAccent,

        ),

      );

    }

  }



  await showModalBottomSheet(

    context: context,

    isScrollControlled: true,

    backgroundColor: context.themeDark,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

    ),

    builder: (sheetCtx) {

      return StatefulBuilder(

        builder: (ctx, setState) {

          Future<void> handleSubmit() async {

            if (supplierId == null) {

              ScaffoldMessenger.of(ctx).showSnackBar(

                const SnackBar(content: Text('Selecione um fornecedor.')),

              );

              return;

            }

            final selected = drafts

                .where((element) => element.include)

                .map(

                  (draft) => draft.toDto(),

                )

                .where((dto) => dto.qty > 0)

                .toList();

            if (selected.isEmpty) {

              ScaffoldMessenger.of(ctx).showSnackBar(

                const SnackBar(

                  content: Text('Selecione ao menos um material para a compra.'),

                ),

              );

              return;

            }

            final dto = CreateOrderPurchaseDto(

              supplierId: supplierId!,

              items: selected,

              freight: _parseCurrencyInput(freightCtrl.text),

              paymentDueDate: paymentDue,

              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),

            );

            final purchase = await controller.createPurchaseForOrder(dto: dto);

            if (purchase != null && ctx.mounted) {

              Navigator.of(sheetCtx).pop();

            }

          }



          return Padding(

            padding: EdgeInsets.only(

              left: 20,

              right: 20,

              top: 24,

              bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,

            ),

            child: SingleChildScrollView(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      const Expanded(

                        child: Text(

                          'Gerar compra de reposio',

                          style: TextStyle(

                            color: Colors.white,

                            fontSize: 18,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                      ),

                      IconButton(

                        icon: const Icon(Icons.close, color: Colors.white54),

                        onPressed: () => Navigator.of(sheetCtx).pop(),

                      ),

                    ],

                  ),

                  const SizedBox(height: 8),

                  GestureDetector(

                    onTap: () async {

                      await pickSupplier(ctx);

                      setState(() {});

                    },

                    child: InputDecorator(

                      decoration: const InputDecoration(

                        labelText: 'Fornecedor',

                        hintText: 'Selecionar fornecedor',

                      ),

                      child: Row(

                        children: [

                          Expanded(

                            child: Text(

                              supplierName ?? 'Selecionar fornecedor',

                              style: TextStyle(

                                color:

                                    supplierName == null

                                        ? Colors.white54

                                        : Colors.white,

                              ),

                            ),

                          ),

                          const Icon(Icons.search, color: Colors.white54),

                        ],

                      ),

                    ),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: freightCtrl,

                    keyboardType:

                        const TextInputType.numberWithOptions(decimal: true),

                    inputFormatters: [MoneyInputFormatter()],

                    decoration: const InputDecoration(

                      labelText: 'Frete (opcional)',

                    ),

                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(

                    icon: const Icon(Icons.event),

                    label: Text(

                      paymentDue == null

                          ? 'Definir vencimento'

                          : DateFormat('dd/MM/yyyy').format(paymentDue!),

                    ),

                    onPressed: () async {

                      final now = DateTime.now();

                      final picked = await showDatePicker(

                        context: ctx,

                        initialDate: paymentDue ?? now,

                        firstDate: DateTime(now.year - 1),

                        lastDate: DateTime(now.year + 2),

                      );

                      if (picked != null) {

                        setState(() => paymentDue = picked);

                      }

                    },

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: notesCtrl,

                    maxLines: 3,

                    decoration: const InputDecoration(

                      labelText: 'Observaes',

                    ),

                  ),

                  const SizedBox(height: 16),

                  const Text(

                    'Materiais da OS',

                    style: TextStyle(

                      color: Colors.white70,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 8),

                  if (drafts.isEmpty)

                    const Text(

                      'Nenhum material para repor.',

                      style: TextStyle(color: Colors.white54),

                    )

                  else

                    ...drafts.map(

                      (draft) => _PurchaseItemCard(

                        form: draft,

                        onToggle: (value) => setState(() => draft.include = value),

                        onChanged: () => setState(() {}),

                      ),

                    ),

                  const SizedBox(height: 20),

                  SizedBox(

                    width: double.infinity,

                    child: ElevatedButton.icon(

                      icon: const Icon(Icons.shopping_cart_outlined),

                      label: const Text('Gerar compra'),

                      onPressed: handleSubmit,

                    ),

                  ),

                ],

              ),

            ),

          );

        },

      );

    },

  ).whenComplete(() {

    freightCtrl.dispose();

    notesCtrl.dispose();

    for (final draft in drafts) {

      draft.dispose();

    }

  });

}



SuppliersService _ensureSuppliersService() {

  if (!Get.isRegistered<SuppliersRepository>()) {

    Get.lazyPut<SuppliersRepository>(

      () => SuppliersRepositoryImpl(),

      fenix: true,

    );

  }

  if (!Get.isRegistered<SuppliersService>()) {

    Get.lazyPut<SuppliersService>(

      () => SuppliersServiceImpl(repo: Get.find()),

      fenix: true,

    );

  }

  return Get.find<SuppliersService>();

}



Future<SupplierModel?> _openSupplierPicker(

  BuildContext context,

  SuppliersService service,

) async {

  final searchCtrl = TextEditingController();

  List<SupplierModel> results = const [];

  bool loading = true;

  bool initialized = false;

  SupplierModel? selected;



  Future<void> runSearch([String query = '']) async {

    loading = true;

    try {

      final fetched = await service.list(text: query.isEmpty ? null : query);

      results = fetched;

    } catch (_) {

      results = const [];

    } finally {

      loading = false;

    }

  }



  await showModalBottomSheet(

    context: context,

    isScrollControlled: true,

    backgroundColor: context.themeDark,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

    ),

    builder: (sheetCtx) => StatefulBuilder(

      builder: (ctx, setState) {

        Future<void> triggerSearch([String term = '']) async {

          setState(() => loading = true);

          await runSearch(term);

          setState(() {});

        }



        if (!initialized) {

          initialized = true;

          Future.microtask(triggerSearch);

        }



        return Padding(

          padding: EdgeInsets.only(

            left: 16,

            right: 16,

            top: 20,

            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                children: [

                  const Expanded(

                    child: Text(

                      'Selecionar fornecedor',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 16,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                  IconButton(

                    icon: const Icon(Icons.close, color: Colors.white54),

                    onPressed: () => Navigator.of(sheetCtx).pop(),

                  ),

                ],

              ),

              const SizedBox(height: 8),

              TextField(

                controller: searchCtrl,

                onChanged: (value) => triggerSearch(value),

                decoration: const InputDecoration(

                  prefixIcon: Icon(Icons.search),

                  labelText: 'Buscar por nome, documento ou telefone',

                ),

              ),

              const SizedBox(height: 12),

              if (loading)

                const Padding(

                  padding: EdgeInsets.symmetric(vertical: 16),

                  child: CircularProgressIndicator(),

                )

              else if (results.isEmpty)

                const Padding(

                  padding: EdgeInsets.symmetric(vertical: 16),

                  child: Text(

                    'Nenhum fornecedor encontrado.',

                    style: TextStyle(color: Colors.white54),

                  ),

                )

              else

                Flexible(

                  child: ListView.separated(

                    shrinkWrap: true,

                    itemCount: results.length,

                    separatorBuilder: (_, __) =>

                        const Divider(color: Colors.white12),

                    itemBuilder: (_, index) {

                      final supplier = results[index];

                      return ListTile(

                        onTap: () {

                          selected = supplier;

                          Navigator.of(sheetCtx).pop();

                        },

                        title: Text(

                          supplier.name,

                          style: const TextStyle(color: Colors.white),

                        ),

                        subtitle: Text(

                          [

                            if ((supplier.docNumber ?? '').isNotEmpty)

                              supplier.docNumber!,

                            if ((supplier.phone ?? '').isNotEmpty)

                              supplier.phone!,

                          ].join('  '),

                          style: const TextStyle(color: Colors.white70),

                        ),

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



  searchCtrl.dispose();

  return selected;

}



double? _parseCurrencyInput(String text) {

  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.isEmpty) return null;

  final value = double.tryParse(digits);

  if (value == null) return null;

  return value / 100;

}



class _OrderPurchaseItemForm {

  _OrderPurchaseItemForm({

    required this.itemId,

    required this.displayName,

    required double qty,

    double? unitCost,

    this.description,

  })  : include = true,

        initialUnitCost = unitCost,

        qtyCtrl = TextEditingController(

          text: qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toString(),

        ),

        costCtrl = TextEditingController(

          text:

              unitCost != null && unitCost > 0

                  ? _orderCurrencyFormatter.format(unitCost)

                  : '',

        ),

        descriptionCtrl = TextEditingController(text: description ?? displayName);



  final String itemId;

  final String displayName;

  final String? description;

  final double? initialUnitCost;

  bool include;

  final TextEditingController qtyCtrl;

  final TextEditingController costCtrl;

  final TextEditingController descriptionCtrl;



  CreateOrderPurchaseItemDto toDto() {

    final qtyValue =

        double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;

    final costValue = _parseCurrencyInput(costCtrl.text) ?? initialUnitCost ?? 0;

    final desc = descriptionCtrl.text.trim();

    return CreateOrderPurchaseItemDto(

      itemId: itemId,

      qty: qtyValue,

      unitCost: costValue,

      description: desc.isEmpty ? null : desc,

      

    );

  }



  void dispose() {

    qtyCtrl.dispose();

    costCtrl.dispose();

    descriptionCtrl.dispose();

  }

}



class _PurchaseItemCard extends StatelessWidget {

  const _PurchaseItemCard({

    required this.form,

    required this.onToggle,

    required this.onChanged,

  });



  final _OrderPurchaseItemForm form;

  final ValueChanged<bool> onToggle;

  final VoidCallback onChanged;



  @override

  Widget build(BuildContext context) {

    return Card(

      color: Colors.white.withValues(alpha: 0.05),

      margin: const EdgeInsets.only(bottom: 12),

      child: Padding(

        padding: const EdgeInsets.all(12),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            SwitchListTile(

              contentPadding: EdgeInsets.zero,

              value: form.include,

              onChanged: onToggle,

              title: Text(

                form.displayName,

                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

              ),

              subtitle: Text(

                'Item ${form.itemId}',

                style: const TextStyle(color: Colors.white70),

              ),

            ),

            const SizedBox(height: 8),

            Row(

              children: [

                Expanded(

                  child: TextField(

                    controller: form.qtyCtrl,

                    enabled: form.include,

                    keyboardType:

                        const TextInputType.numberWithOptions(decimal: true),

                    decoration: const InputDecoration(labelText: 'Quantidade'),

                    onChanged: (_) => onChanged(),

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: TextField(

                    controller: form.costCtrl,

                    enabled: form.include,

                    keyboardType:

                        const TextInputType.numberWithOptions(decimal: true),

                    inputFormatters: [MoneyInputFormatter()],

                    decoration: const InputDecoration(labelText: 'Custo unitrio'),

                    onChanged: (_) => onChanged(),

                  ),

                ),

              ],

            ),

            const SizedBox(height: 8),

            TextField(

              controller: form.descriptionCtrl,

              enabled: form.include,

              decoration: const InputDecoration(

                labelText: 'Descrio do item',

              ),

              onChanged: (_) => onChanged(),

            ),

          ],

        ),

      ),

    );

  }

}



class _StatusItem {

  const _StatusItem({

    required this.label,

    required this.color,

    required this.icon,

  });



  final String label;

  final Color color;

  final IconData icon;

}



class _ChecklistToggle {

  _ChecklistToggle({required this.label, required this.done});



  final String label;

  bool done;

}
