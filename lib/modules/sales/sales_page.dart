import 'dart:async';



import 'package:air_sync/application/auth/auth_service_application.dart';

import 'package:air_sync/application/ui/input_formatters.dart';

import 'package:air_sync/application/ui/widgets/ai_loading_overlay.dart';

import 'package:air_sync/application/ui/theme_extensions.dart';

import 'package:air_sync/models/client_model.dart';

import 'package:air_sync/models/inventory_model.dart';

import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/sale_model.dart';

import 'package:air_sync/modules/sales/sales_controller.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:intl/intl.dart';



class SalesPage extends GetView<SalesController> {

  const SalesPage({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: context.themeBg,

      appBar: AppBar(

        title: const Text('Vendas'),

        backgroundColor: Colors.transparent,

        elevation: 0,

        actions: [

          IconButton(

            tooltip: 'Recarregar',

            onPressed: controller.load,

            icon: const Icon(Icons.refresh),

          ),

        ],

      ),

      floatingActionButton: FloatingActionButton(

        backgroundColor: context.themeGreen,

        onPressed: () => _openSaleForm(context, controller),

        child: const Icon(Icons.add, color: Colors.white, size: 30),

      ),

      body: SafeArea(

        child: Column(

          children: [

            Padding(

              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),

              child: _SalesSearchField(controller: controller),

            ),

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              child: _SalesStatusFilter(controller: controller),

            ),

            Expanded(

              child: Obx(() {

                final loading = controller.isLoading.value;

                final entries = controller.filteredSales;

                if (loading && entries.isEmpty) {

                  return const Center(child: CircularProgressIndicator());

                }

                if (entries.isEmpty) {

                  return RefreshIndicator(

                    onRefresh: controller.load,

                    child: ListView(

                      physics: const AlwaysScrollableScrollPhysics(),

                      children: const [

                        SizedBox(height: 80),

                        Icon(Icons.sell_outlined, size: 72, color: Colors.white24),

                        SizedBox(height: 12),

                        Text(

                          'Nenhuma venda encontrada',

                          textAlign: TextAlign.center,

                          style: TextStyle(color: Colors.white70, fontSize: 16),

                        ),

                      ],

                    ),

                  );

                }

                return RefreshIndicator(

                  onRefresh: controller.load,

                  child: ListView.separated(

                    physics: const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),

                    itemCount: entries.length,

                    separatorBuilder: (_, __) => const SizedBox(height: 12),

                    itemBuilder: (_, index) => _SaleCard(

                      sale: entries[index],

                      controller: controller,

                    ),

                  ),

                );

              }),

            ),

          ],

        ),

      ),

    );

  }

}



class _SalesSearchField extends StatelessWidget {

  const _SalesSearchField({required this.controller});



  final SalesController controller;



  @override

  Widget build(BuildContext context) {

    return TextField(

      controller: controller.searchCtrl,

      onChanged: controller.onSearchChanged,

      decoration: const InputDecoration(

        prefixIcon: Icon(Icons.search),

        labelText: 'Buscar vendas (cliente, ttulo ou OS)',

      ),

    );

  }

}



class _SalesStatusFilter extends StatelessWidget {

  const _SalesStatusFilter({required this.controller});



  final SalesController controller;

  static const statuses = ['all', 'draft', 'pending', 'approved', 'fulfilled', 'cancelled'];



  String _label(String status) {

    switch (status) {

      case 'draft':

        return 'Rascunho';

      case 'pending':

        return 'Pendente';

      case 'approved':

        return 'Aprovada';

      case 'fulfilled':

        return 'Concluda';

      case 'cancelled':

        return 'Cancelada';

      default:

        return 'Todas';

    }

  }



  @override

  Widget build(BuildContext context) {

    return Obx(

      () => SingleChildScrollView(

        scrollDirection: Axis.horizontal,

        child: Row(

          children: statuses

              .map(

                (status) => Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 4),

                  child: ChoiceChip(

                    label: Text(_label(status)),

                    selected: controller.statusFilter.value == status,

                    onSelected: (_) => controller.setStatusFilter(status),

                  ),

                ),

              )

              .toList(),

        ),

      ),

    );

  }

}



class _SaleCard extends StatelessWidget {

  const _SaleCard({required this.sale, required this.controller});



  final SaleModel sale;

  final SalesController controller;



  Color _statusColor(BuildContext context) {

    switch (sale.status.toLowerCase()) {

      case 'approved':

        return context.themeGreen;

      case 'fulfilled':

        return Colors.blueAccent;

      case 'cancelled':

        return Colors.redAccent;

      default:

        return Colors.orangeAccent;

    }

  }



  @override

  Widget build(BuildContext context) {

    final dateFmt = DateFormat('dd/MM/yyyy');

    final statusColor = _statusColor(context);

    return InkWell(

      onTap: () => _openSaleDetail(context, sale, controller),

      child: Container(

        decoration: BoxDecoration(

          color: Colors.white10,

          borderRadius: BorderRadius.circular(12),

        ),

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Expanded(

                  child: Text(

                    sale.displayTitle,

                    style: const TextStyle(

                      color: Colors.white,

                      fontWeight: FontWeight.bold,

                      fontSize: 16,

                    ),

                  ),

                ),

                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                  decoration: BoxDecoration(

                    color: statusColor.withValues(alpha: 0.1),

                    borderRadius: BorderRadius.circular(20),

                  ),

                  child: Text(

                    sale.status.toUpperCase(),

                    style: TextStyle(color: statusColor, fontSize: 12),

                  ),

                ),

              ],

            ),

            const SizedBox(height: 8),

            Text(

              sale.customerName ?? 'Cliente não informado',

              style: const TextStyle(color: Colors.white70),

            ),

            const SizedBox(height: 4),

            Text(

              sale.formattedTotal,

              style: const TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.w600,

                fontSize: 18,

              ),

            ),

            if (sale.expectedAt != null) ...[

              const SizedBox(height: 4),

              Text(

                'Entrega: ${dateFmt.format(sale.expectedAt!.toLocal())}',

                style: const TextStyle(color: Colors.white70, fontSize: 13),

              ),

            ],

            if (sale.autoCreateOrder) ...[

              const SizedBox(height: 4),

              Row(

                children: const [

                  Icon(Icons.auto_fix_high, size: 14, color: Colors.white54),

                  SizedBox(width: 6),

                  Text(

                    'OS automtica habilitada',

                    style: TextStyle(color: Colors.white70, fontSize: 12),

                  ),

                ],

              ),

            ],

            if ((sale.linkedOrderId ?? '').isNotEmpty) ...[

              const SizedBox(height: 8),

              TextButton.icon(

                onPressed: () => controller.openLinkedOrder(sale.linkedOrderId!),

                icon: const Icon(Icons.open_in_new, size: 16),

                label: Text(

                  'Abrir OS ${sale.linkedOrderId}',

                  style: const TextStyle(color: Colors.white),

                ),

              ),

            ],

            const SizedBox(height: 8),

            _SaleInsightsActions(sale: sale, controller: controller),

            const SizedBox(height: 8),

            Wrap(

              spacing: 8,

              children: [

                if ((sale.linkedOrderId ?? '').isEmpty &&

                    (sale.status.toLowerCase() == 'approved' ||

                        sale.status.toLowerCase() == 'fulfilled'))

                  OutlinedButton.icon(

                    onPressed: () => controller.launchOrder(sale: sale),

                    icon: const Icon(Icons.precision_manufacturing_outlined, size: 16),

                    label: const Text('Gerar OS'),

                  ),

                if (sale.canApprove)

                  OutlinedButton(

                    onPressed: () => controller.approveSale(sale.id),

                    child: const Text('Aprovar'),

                  ),

                if (sale.canFulfill)

                  OutlinedButton(

                    onPressed: () => controller.fulfillSale(sale.id),

                    child: const Text('Atender'),

                  ),

                if (sale.canCancel)

                  TextButton(

                    onPressed: () => controller.cancelSale(sale.id),

                    child: const Text('Cancelar'),

                  ),

                IconButton(

                  tooltip: 'Editar',

                  onPressed: () => _openSaleForm(

                    context,

                    controller,

                    existing: sale,

                  ),

                  icon: const Icon(Icons.edit, color: Colors.white70),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}



class _SaleInsightsActions extends StatelessWidget {

  const _SaleInsightsActions({required this.sale, required this.controller});



  final SaleModel sale;

  final SalesController controller;



  @override

  Widget build(BuildContext context) {

    return Wrap(

      spacing: 8,

      runSpacing: 8,

      children: [

        OutlinedButton.icon(

          icon: const Icon(Icons.description_outlined),

          label: const Text('Gerar proposta'),

          onPressed: () => _showSaleProposal(context, controller, sale),

        ),

        OutlinedButton.icon(

          icon: const Icon(Icons.chat_bubble_outline),

          label: const Text('Assistente comercial'),

          onPressed: () => _openSaleAssistant(context, controller, sale),

        ),

      ],

    );

  }

}



void _openSaleDetail(

  BuildContext context,

  SaleModel sale,

  SalesController controller,

) {

  showModalBottomSheet(

    context: context,

    backgroundColor: context.themeDark,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

    ),

    isScrollControlled: true,

    builder: (ctx) => Padding(

      padding: EdgeInsets.only(

        left: 20,

        right: 20,

        top: 20,

        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,

      ),

      child: SingleChildScrollView(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Expanded(

                  child: Text(

                    sale.displayTitle,

                    style: const TextStyle(

                      color: Colors.white,

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ),

                IconButton(

                  onPressed: () => Navigator.of(ctx).pop(),

                  icon: const Icon(Icons.close, color: Colors.white70),

                ),

              ],

            ),

            const SizedBox(height: 12),

            Text(

              sale.formattedTotal,

              style: const TextStyle(

                color: Colors.white,

                fontSize: 22,

                fontWeight: FontWeight.w600,

              ),

            ),

            const SizedBox(height: 8),

            _SaleItemsSection(items: sale.items),

            const SizedBox(height: 12),

            _SaleInsightsActions(sale: sale, controller: controller),

            if ((sale.linkedOrderId ?? '').isEmpty &&

                (sale.status.toLowerCase() == 'approved' ||

                    sale.status.toLowerCase() == 'fulfilled')) ...[

              const SizedBox(height: 12),

              SizedBox(

                width: double.infinity,

                child: OutlinedButton.icon(

                  onPressed: () => controller.launchOrder(sale: sale),

                  icon: const Icon(Icons.precision_manufacturing_outlined),

                  label: const Text('Gerar OS automaticamente'),

                ),

              ),

            ],

            const SizedBox(height: 12),

            _SaleHistoryTimeline(entries: sale.history),

            const SizedBox(height: 12),

            Row(

              children: [

                Expanded(

                  child: ElevatedButton(

                    onPressed: sale.canApprove ? () => controller.approveSale(sale.id) : null,

                    child: const Text('Aprovar'),

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: ElevatedButton(

                    onPressed: sale.canFulfill ? () => controller.fulfillSale(sale.id) : null,

                    child: const Text('Atender'),

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



class _SaleItemsSection extends StatelessWidget {

  const _SaleItemsSection({required this.items});



  final List<SaleItemModel> items;



  @override

  Widget build(BuildContext context) {

    if (items.isEmpty) {

      return const SizedBox();

    }

    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'Itens',

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.bold,

          ),

        ),

        const SizedBox(height: 8),

        ...items.map(

          (item) {

            final typeLabel = item.type == 'product' ? 'Produto' : 'Serviço';

            final qtyText =
                item.quantity % 1 == 0 ? item.quantity.toStringAsFixed(0) : item.quantity.toStringAsFixed(2);

            return ListTile(

              dense: true,

              contentPadding: EdgeInsets.zero,

              title: Text(item.name, style: const TextStyle(color: Colors.white)),

              subtitle: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    item.requiresInstallation ? '$typeLabel • Requer instalação' : typeLabel,

                    style: const TextStyle(color: Colors.white70, fontSize: 12),

                  ),

                  Text(

                    'Qtd: $qtyText  •  Unit: ${item.unitPrice != null ? money.format(item.unitPrice) : 'N/D'}',

                    style: const TextStyle(color: Colors.white70, fontSize: 12),

                  ),

                ],

              ),

              trailing: Text(

                item.total != null ? money.format(item.total) : '',

                style: const TextStyle(color: Colors.white),

              ),

            );

          },

        ),

      ],

    );

  }

}



class _SaleHistoryTimeline extends StatelessWidget {

  const _SaleHistoryTimeline({required this.entries});



  final List<SaleHistoryEntry> entries;



  @override

  Widget build(BuildContext context) {

    if (entries.isEmpty) return const SizedBox.shrink();

    final dateFmt = DateFormat('dd/MM HH:mm');

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(

          'Timeline',

          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

        ),

        const SizedBox(height: 8),

        ...entries.map(

          (entry) => ListTile(

            contentPadding: EdgeInsets.zero,

            leading: const Icon(Icons.bolt, color: Colors.orangeAccent),

            title: Text(

              entry.status,

              style: const TextStyle(color: Colors.white),

            ),

            subtitle: Text(

              [

                if (entry.userName != null) entry.userName!,

                if (entry.createdAt != null) dateFmt.format(entry.createdAt!.toLocal()),

                if ((entry.message ?? '').isNotEmpty) entry.message!,

              ].join(' ? '),

              style: const TextStyle(color: Colors.white70),

            ),

          ),

        ),

      ],

    );

  }

}



Future<void> _showSaleProposal(

  BuildContext context,

  SalesController controller,

  SaleModel sale,

) async {

  final hideOverlay = AiLoadingOverlay.show(

    context,

    message: 'Gerando proposta com IA...',

  );

  final text = await controller.generateProposalText(sale.id);

  hideOverlay();

  if (text == null || !context.mounted) return;

  await showDialog(

    context: context,

    builder: (ctx) => AlertDialog(

      backgroundColor: context.themeDark,

      title: const Text('Proposta sugerida'),

      content: SizedBox(

        width: double.maxFinite,

        child: SingleChildScrollView(

          child: SelectableText(text),

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



Future<void> _openSaleAssistant(

  BuildContext context,

  SalesController controller,

  SaleModel sale,

) async {

  final questionCtrl = TextEditingController();

  String? answer;

  bool submitting = false;



  // ignore: use_build_context_synchronously
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

              message: 'Consultando assistente comercial...',

            );

            try {

              final result = await controller.askCommercialAssistant(

                sale.id,

                question,

              );

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

                        'Assistente comercial',

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

                    labelText: 'Escreva a pergunta ou contexto da proposta',

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



Future<void> _openSaleForm(
  BuildContext context,
  SalesController controller, {
  SaleModel? existing,
}) async {
  final authService = Get.find<AuthServiceApplication>();
  final allowAutoOrder =
      authService.user.value?.hasPermission('orders.write') ?? false;
  final formKey = GlobalKey<FormState>();
  final existingDiscount = existing?.discount;
  final customerCtrl = TextEditingController(
    text: existing?.clientName ?? existing?.customerName ?? '',
  );
  final discountCtrl = TextEditingController(
    text: existingDiscount != null && existingDiscount > 0
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(existingDiscount)
        : '',
  );
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  final selectedClientId = RxnString(existing?.clientId);
  final selectedLocationId = RxnString(existing?.locationId);
  final autoCreateOrder = RxBool(existing?.autoCreateOrder ?? false);
  final locationsLoading = false.obs;
  final locationOptions = <LocationModel>[].obs;
  final itemDrafts = RxList<_SaleItemDraft>(
    existing?.items.map(_SaleItemDraft.fromSaleItem).toList() ??
        <_SaleItemDraft>[],
  );
  final moneyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double? parseCurrency(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.parse(digits) / 100;
  }

  String formatQty(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Future<void> loadLocations(String clientId) async {
    locationsLoading(true);
    final data = await controller.fetchLocations(clientId);
    locationOptions.assignAll(data);
    if (data.isEmpty) {
      selectedLocationId.value = null;
    } else {
      final current = selectedLocationId.value;
      LocationModel? match;
      if (current != null) {
        for (final loc in data) {
          if (loc.id == current) {
            match = loc;
            break;
          }
        }
      }
      selectedLocationId.value = (match ?? data.first).id;
    }
    locationsLoading(false);
  }

  if ((selectedClientId.value ?? '').isNotEmpty) {
    await loadLocations(selectedClientId.value!);
  }

  void showWarning(String text) {
    Get.snackbar(
      'Vendas',
      text,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }

  void addItem({InventoryItemModel? stockItem}) {
    final nameCtrl = TextEditingController(text: stockItem?.name ?? '');
    final qtyCtrl = TextEditingController(text: '1');
    final double defaultPrice =
        stockItem?.sellPrice ?? stockItem?.avgCost ?? 0;
    final priceCtrl = TextEditingController(
      text: defaultPrice > 0
          ? moneyFormatter.format(defaultPrice)
          : '',
    );
    String selectedType = stockItem != null ? 'product' : 'service';
    bool requiresInstallation = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            stockItem == null ? 'Adicionar item' : 'Adicionar item do estoque',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'service', child: Text('Serviço')),
                    DropdownMenuItem(value: 'product', child: Text('Produto')),
                  ],
                  onChanged: stockItem != null
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => selectedType = value);
                        },
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do item'),
                ),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Valor unitário'),
                ),
                SwitchListTile.adaptive(
                  value: requiresInstallation,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) =>
                      setState(() => requiresInstallation = value),
                  title: const Text('Requer instalação'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;
                final unit = parseCurrency(priceCtrl.text) ?? 0;
                itemDrafts.add(
                  _SaleItemDraft(
                    type: selectedType,
                    name: name,
                    quantity: qty <= 0 ? 1 : qty,
                    unitPrice: unit,
                    inventoryItemId: stockItem?.id,
                    requiresInstallation: requiresInstallation,
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      qtyCtrl.dispose();
      priceCtrl.dispose();
    });
  }

  await showModalBottomSheet(
    // ignore: use_build_context_synchronously
    context: context,
    isScrollControlled: true,
    // ignore: use_build_context_synchronously
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
      ),
      child: Form(
        key: formKey,
        child: Obx(
          () => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Nova venda' : 'Editar venda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: customerCtrl,
                  readOnly: true,
                  validator: (_) =>
                      (selectedClientId.value ?? '').isEmpty ? 'Selecione um cliente' : null,
                  onTap: () async {
                    // ignore: use_build_context_synchronously
                    final client = await _openClientPicker(sheetCtx, controller);
                    if (client != null) {
                      customerCtrl.text = client.name;
                      selectedClientId.value = client.id;
                      await loadLocations(client.id);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    hintText: 'Selecione o cliente',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if ((selectedClientId.value ?? '').isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              selectedClientId.value = null;
                              selectedLocationId.value = null;
                              locationOptions.clear();
                              customerCtrl.clear();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            // ignore: use_build_context_synchronously
                            final client = await _openClientPicker(sheetCtx, controller);
                            if (client != null) {
                              customerCtrl.text = client.name;
                              selectedClientId.value = client.id;
                              await loadLocations(client.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: locationOptions.isEmpty ? null : selectedLocationId.value,
                    items: locationOptions
                        .map(
                          (loc) => DropdownMenuItem<String>(
                            value: loc.id,
                            child: Text(_formatLocationLabel(loc)),
                          ),
                        )
                        .toList(),
                    onChanged: selectedClientId.value == null || locationOptions.isEmpty
                        ? null
                        : (value) => selectedLocationId.value = value,
                    validator: (_) {
                      if ((selectedClientId.value ?? '').isEmpty) {
                        return 'Selecione um cliente primeiro';
                      }
                      if ((selectedLocationId.value ?? '').isEmpty) {
                        return 'Selecione um local de atendimento';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Local de atendimento',
                      helperText: selectedClientId.value == null
                          ? 'Escolha um cliente para carregar os locais'
                          : (locationOptions.isEmpty
                              ? 'Nenhum local encontrado para este cliente'
                              : 'Defina onde o atendimento ocorrerá'),
                    ),
                  ),
                ),
                Obx(
                  () => locationsLoading.value
                      ? const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: LinearProgressIndicator(),
                        )
                      : Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: selectedClientId.value == null
                                ? null
                                : () => loadLocations(selectedClientId.value!),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Atualizar locais'),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Desconto (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                if (allowAutoOrder)
                  Obx(
                    () => SwitchListTile.adaptive(
                      value: autoCreateOrder.value,
                      onChanged: (value) => autoCreateOrder.value = value,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gerar OS automaticamente'),
                      subtitle: const Text(
                        'A venda será aprovada e uma OS será criada imediatamente.',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Itens',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => addItem(),
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Manual'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final inventory = await _openInventoryPicker(sheetCtx, controller);
                        if (inventory != null) {
                          addItem(stockItem: inventory);
                        }
                      },
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Estoque'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(
                  () {
                    if (itemDrafts.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Nenhum item adicionado até o momento.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return Column(
                      children: itemDrafts
                          .asMap()
                          .entries
                          .map(
                            (entry) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                entry.value.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.requiresInstallation
                                        ? '${entry.value.typeLabel} • Requer instalação'
                                        : entry.value.typeLabel,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    'Qtd: ${formatQty(entry.value.quantity)}  •  Unit: '
                                    '${moneyFormatter.format(entry.value.unitPrice)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if ((entry.value.inventoryItemId ?? '').isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.inventory_2_rounded,
                                        color: Colors.tealAccent,
                                        size: 18,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => itemDrafts.removeAt(entry.key),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      FocusScope.of(sheetCtx).unfocus();
                      if (!formKey.currentState!.validate()) return;
                      if (itemDrafts.isEmpty) {
                        showWarning('Adicione pelo menos um item.');
                        return;
                      }
                      final clientId = selectedClientId.value;
                      final locationId = selectedLocationId.value;
                      if ((clientId ?? '').isEmpty) {
                        showWarning('Selecione um cliente.');
                        return;
                      }
                      if ((locationId ?? '').isEmpty) {
                        showWarning('Selecione um local de atendimento.');
                        return;
                      }
                      final navigator = Navigator.of(sheetCtx);
                      final items = itemDrafts.map((draft) => draft.toModel()).toList();
                      final discountValue = parseCurrency(discountCtrl.text);
                      final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                      final autoOrderValue =
                          allowAutoOrder ? autoCreateOrder.value : (existing?.autoCreateOrder ?? false);

                      if (existing == null) {
                        await controller.createSale(
                          clientId: clientId!,
                          locationId: locationId!,
                          items: items,
                          discount: discountValue,
                          notes: notes,
                          moveRequest: null,
                          autoCreateOrder: autoOrderValue,
                        );
                      } else {
                        await controller.updateSale(
                          id: existing.id,
                          clientId: clientId,
                          locationId: locationId,
                          items: items,
                          discount: discountValue,
                          notes: notes,
                          moveRequest: null,
                          autoCreateOrder: allowAutoOrder ? autoCreateOrder.value : null,
                        );
                      }

                      if (navigator.mounted) {
                        navigator.pop();
                      }
                    },
                                        child: Text(existing == null ? 'Criar venda' : 'Salvar alterações'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  customerCtrl.dispose();
  discountCtrl.dispose();
  notesCtrl.dispose();
}

Future<ClientModel?> _openClientPicker(
  BuildContext context,
  SalesController controller,
) async {

  final searchCtrl = TextEditingController();

  List<ClientModel> results = const [];

  bool loading = true;

  bool initialized = false;



  ClientModel? selected;



  await showModalBottomSheet<void>(

    context: context,

    isScrollControlled: true,

    backgroundColor: context.themeDark,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

    ),

    builder: (sheetCtx) => StatefulBuilder(

      builder: (ctx, setState) {

        Future<void> runSearch([String term = '']) async {

          setState(() => loading = true);

          final fetched = await controller.fetchClients(term);

          setState(() {

            results = fetched;

            loading = false;

          });

        }



        if (!initialized) {

          initialized = true;

          Future.microtask(() => runSearch());

        }



        return Padding(

          padding: EdgeInsets.only(

            left: 16,

            right: 16,

            top: 16,

            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                children: [

                  const Text(

                    'Selecionar cliente',

                    style: TextStyle(

                      color: Colors.white,

                      fontWeight: FontWeight.bold,

                      fontSize: 16,

                    ),

                  ),

                  const Spacer(),

                  IconButton(

                    onPressed: () => Navigator.of(ctx).pop(),

                    icon: const Icon(Icons.close, color: Colors.white70),

                  ),

                ],

              ),

              const SizedBox(height: 8),

              TextField(

                controller: searchCtrl,

                onChanged: (value) => runSearch(value),

                decoration: const InputDecoration(

                  labelText: 'Buscar cliente (nome, doc ou telefone)',

                  prefixIcon: Icon(Icons.search),

                ),

              ),

              const SizedBox(height: 12),

              if (loading)

                const Padding(

                  padding: EdgeInsets.symmetric(vertical: 20),

                  child: CircularProgressIndicator(),

                )

              else if (results.isEmpty)

                const Padding(

                  padding: EdgeInsets.symmetric(vertical: 20),

                  child: Text(

                    'Nenhum cliente encontrado',

                    style: TextStyle(color: Colors.white70),

                  ),

                )

              else

                Flexible(

                  child: ListView.separated(

                    shrinkWrap: true,

                    itemCount: results.length,

                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),

                    itemBuilder: (_, index) {

                      final client = results[index];

                      final subtitleParts = [

                        if ((client.docNumber ?? '').isNotEmpty) client.docNumber!,

                        if (client.phones.isNotEmpty) client.phones.first,

                      ];

                      return ListTile(

                        onTap: () {

                          selected = client;

                          Navigator.of(ctx).pop();

                        },

                        title: Text(

                          client.name,

                          style: const TextStyle(color: Colors.white),

                        ),

                        subtitle: subtitleParts.isEmpty

                            ? null

                            : Text(

                                subtitleParts.join(' ? '),

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



Future<InventoryItemModel?> _openInventoryPicker(

  BuildContext context,

  SalesController controller,

) async {

  final searchCtrl = TextEditingController();

  List<InventoryItemModel> results = const [];

  bool loading = true;

  bool initialized = false;

  InventoryItemModel? selected;



  await showModalBottomSheet<void>(

    context: context,

    isScrollControlled: true,

    backgroundColor: context.themeDark,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

    ),

    builder: (sheetCtx) => StatefulBuilder(

      builder: (ctx, setState) {

        Future<void> runSearch([String term = '']) async {

          setState(() => loading = true);

          final fetched = await controller.fetchInventory(search: term);

          setState(() {

            results = fetched;

            loading = false;

          });

        }



        if (!initialized) {

          initialized = true;

          Future.microtask(() => runSearch());

        }



        return Padding(

          padding: EdgeInsets.only(

            left: 16,

            right: 16,

            top: 16,

            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                children: [

                  const Text(

                    'Itens do estoque',

                    style: TextStyle(

                      color: Colors.white,

                      fontWeight: FontWeight.bold,

                      fontSize: 16,

                    ),

                  ),

                  const Spacer(),

                  IconButton(

                    onPressed: () => Navigator.of(ctx).pop(),

                    icon: const Icon(Icons.close, color: Colors.white70),

                  ),

                ],

              ),

              const SizedBox(height: 8),

              TextField(

                controller: searchCtrl,

                onChanged: (value) => runSearch(value),

                decoration: const InputDecoration(

                  labelText: 'Buscar item (nome, SKU ou cdigo)',

                  prefixIcon: Icon(Icons.search),

                ),

              ),

              const SizedBox(height: 12),

              if (loading)

                const Padding(

                  padding: EdgeInsets.symmetric(vertical: 20),

                  child: CircularProgressIndicator(),

                )

              else if (results.isEmpty)

                const Padding(

                  padding: EdgeInsets.symmetric(vertical: 20),

                  child: Text(

                    'Nenhum item encontrado',

                    style: TextStyle(color: Colors.white70),

                  ),

                )

              else

                Flexible(

                  child: ListView.separated(

                    shrinkWrap: true,

                    itemCount: results.length,

                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),

                    itemBuilder: (_, index) {

                      final item = results[index];

                      final subtitle = [

                        if (item.sku.isNotEmpty) 'SKU ${item.sku}',

                        'Estoque ${item.quantity.toStringAsFixed(0)} ${item.unit}',

                      ].join(' ? ');

                      final sellPrice = item.sellPrice ?? item.avgCost ?? 0;

                      return ListTile(

                        onTap: () {

                          selected = item;

                          Navigator.of(ctx).pop();

                        },

                        title: Text(

                          item.description,

                          style: const TextStyle(color: Colors.white),

                        ),

                        subtitle: Text(

                          subtitle,

                          style: const TextStyle(color: Colors.white70),

                        ),

                        trailing: Text(

                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')

                              .format(sellPrice),

                          style: const TextStyle(color: Colors.white),

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





String _formatLocationLabel(LocationModel model) {
  final parts = <String>[];
  if (model.label.trim().isNotEmpty) {
    parts.add(model.label.trim());
  }
  final address = model.addressLine.trim();
  if (address.isNotEmpty) {
    parts.add(address);
  }
  final cityState = model.cityState.trim();
  if (cityState.isNotEmpty) {
    parts.add(cityState);
  }
  return parts.isEmpty ? model.id : parts.join(' • ');
}

class _SaleItemDraft {
  const _SaleItemDraft({
    required this.type,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.inventoryItemId,
    this.requiresInstallation = false,
  });

  final String type;
  final String name;
  final double quantity;
  final double unitPrice;
  final String? inventoryItemId;
  final bool requiresInstallation;

  factory _SaleItemDraft.fromSaleItem(SaleItemModel item) => _SaleItemDraft(
        type: item.type,
        name: item.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice ?? 0,
        inventoryItemId: item.inventoryItemId,
        requiresInstallation: item.requiresInstallation,
      );

  String get typeLabel => type == 'product' ? 'Produto' : 'Serviço';

  SaleItemModel toModel() => SaleItemModel(
        type: type,
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        total: unitPrice * quantity,
        inventoryItemId: inventoryItemId,
        requiresInstallation: requiresInstallation,
      );
}



