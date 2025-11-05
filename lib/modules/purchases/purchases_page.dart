import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/core/form_validator.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'purchases_controller.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/modules/inventory/inventory_page.dart';
import 'package:intl/intl.dart';

class PurchasesPage extends GetView<PurchasesController> {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final hasItems = controller.items.isNotEmpty;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged:
                    (v) => controller.filter.value = v.trim().toLowerCase(),
                decoration: const InputDecoration(
                  labelText: 'Buscar por fornecedor, status ou ID',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: Stack(
                  children: [
                    hasItems
                        ? _buildGroupedList(context)
                        : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Registre compras para dar entrada no estoque e atualizar o custo médio. Toque no botão + para adicionar.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                SizedBox(height: 30),
                                Center(
                                  child: Text(
                                    'Sem compras cadastradas',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (isLoading) const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGroupedList(BuildContext context) {
    final q = controller.filter.value.trim().toLowerCase();
    final base =
        controller.items.where((p) {
          if (q.isEmpty) return true;
          final supplier =
              controller.supplierNameFor(p.supplierId).toLowerCase();
          final s = p.status.toLowerCase();
          final statusPt =
              s == 'ordered'
                  ? 'pedido'
                  : s == 'received'
                  ? 'recebida'
                  : (s == 'canceled' || s == 'cancelled')
                  ? 'cancelada'
                  : s;
          return supplier.contains(q) ||
              statusPt.contains(q) ||
              p.id.toLowerCase().contains(q);
        }).toList();

    final abertas =
        base
            .where(
              (e) =>
                  e.status.toLowerCase() != 'received' &&
                  e.status.toLowerCase() != 'canceled' &&
                  e.status.toLowerCase() != 'cancelled',
            )
            .toList();
    final recebidas =
        base.where((e) => e.status.toLowerCase() == 'received').toList();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return ListView(
      children: [
        if (abertas.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Em aberto',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...abertas.map((p) {
            final s = p.status.toLowerCase();
            final statusPt =
                s == 'ordered'
                    ? 'Pedido'
                    : s == 'received'
                    ? 'Recebida'
                    : s == 'canceled' || s == 'cancelled'
                    ? 'Cancelada'
                    : p.status;
            final subtotal =
                (p.subtotal ??
                    p.items.fold<double>(
                      0,
                      (sum, e) => sum + (e.qty * e.unitCost),
                    ));
            return ListTile(
              onTap: () => _openPurchaseDetailsBottomSheet(context, p),
              title: Text(
                'Fornecedor: ${controller.supplierNameFor(p.supplierId)}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Status: $statusPt - Itens: ${p.items.length} - Subtotal: ${currency.format(subtotal)}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: SizedBox(
                width: 140,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        currency.format(p.total),
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.greenAccent),
                      ),
                      onPressed: () => _openReceiveBottomSheet(context, p.id),
                      child: const Text(
                        'Receber',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
        if (recebidas.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              'Recebidas',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...recebidas.map((p) {
            return ListTile(
              onTap: () => _openPurchaseDetailsBottomSheet(context, p),
              title: Text(
                'Fornecedor: ${controller.supplierNameFor(p.supplierId)}',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Status: Recebida - Itens: ${p.items.length}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Text(
                currency.format(p.total),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  void _openPurchaseDetailsBottomSheet(
    BuildContext context,
    PurchaseModel p,
  ) async {
    final items = p.items;
    await Get.find<PurchasesController>().ensureItemNamesLoaded();
    final names = Map<String, String>.from(
      Get.find<PurchasesController>().itemNames,
    );
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
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
                      _openEditBottomSheet(context, p);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fornecedor: ${Get.find<PurchasesController>().supplierNameFor(p.supplierId)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Status: $statusPt',
                style: const TextStyle(color: Colors.white70),
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
                      subtitle: Text(
                        'Qtd: ${it.qty} - Unit: ${currency.format(it.unitCost)} - Total: ${currency.format(lineTotal)}',
                        style: const TextStyle(color: Colors.white70),
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
              if (p.status.toLowerCase() != 'received' &&
                  p.status.toLowerCase() != 'canceled' &&
                  p.status.toLowerCase() != 'cancelled')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeGreen,
                    ),
                    onPressed: () => _openReceiveBottomSheet(context, p.id),
                    child: const Text('Marcar como recebida'),
                  ),
                ),
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

  void _openCreateBottomSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final notesCtrl = TextEditingController();
    final supplierNameCtrl = TextEditingController();
    final supplierId = RxnString();

    final itemNameCtrl = TextEditingController();
    String? selectedItemId;
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: '0');
    final freightCtrl = TextEditingController();
    final status = 'ordered'.obs;
    final items = <PurchaseItemModel>[].obs;
    final displayItems = <Map<String, dynamic>>[].obs;

    Future<void> pickSupplier() async {
      final service = Get.find<SuppliersService>();
      final list = RxList<SupplierModel>(await service.list(text: ''));
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
                },
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
                            [
                              list[i].docNumber,
                              list[i].phone,
                            ].where((e) => (e ?? '').isNotEmpty).join(' - '),
                          ),
                          onTap: () {
                            supplierId.value = list[i].id;
                            supplierNameCtrl.text = list[i].name;
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
                      'Nova compra',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: supplierNameCtrl,
                      readOnly: true,
                      onTap: pickSupplier,
                      validator:
                          (v) =>
                              supplierId.value == null
                                  ? 'Selecione o fornecedor'
                                  : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor',
                        labelStyle: TextStyle(color: Colors.white),
                        suffixIcon: Icon(Icons.search),
                      ),
                    ),
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
                            keyboardType: TextInputType.number,
                            validator:
                                (v) => FormValidators.validateOptionalNumber(
                                  v,
                                  fieldName: 'Frete',
                                  positive: true,
                                ),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Frete (opcional)',
                              prefixText: 'R\$ ',
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
                              ),
                            );
                            displayItems.add({
                              'name': itemNameCtrl.text,
                              'qty': qty,
                              'unit': unit,
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
                            return ListTile(
                              dense: true,
                              title: Text(
                                it['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Qtd: ${it['qty']} - Unit: R\$ ${(it['unit'] as double).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  items.removeAt(i);
                                  displayItems.removeAt(i);
                                },
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
                                        if (!formKey.currentState!.validate())
                                          return;
                                        final freight =
                                            freightCtrl.text.trim().isEmpty
                                                ? null
                                                : double.tryParse(
                                                  freightCtrl.text
                                                      .trim()
                                                      .replaceAll(',', '.'),
                                                );
                                        final ctrl =
                                            Get.find<PurchasesController>();
                                        final created = await ctrl.create(
                                          supplierId: supplierId.value!,
                                          items: items.toList(),
                                          status: status.value,
                                          freight: freight,
                                          notes:
                                              notesCtrl.text.trim().isNotEmpty
                                                  ? notesCtrl.text.trim()
                                                  : null,
                                        );
                                        if (created != null) {
                                          if (status.value == 'received' &&
                                              created.status.toLowerCase() !=
                                                  'received') {
                                            await ctrl.receive(
                                              created.id,
                                              receivedAt: DateTime.now(),
                                            );
                                          } else if (created.status.toLowerCase() ==
                                                  'received' &&
                                              Get.isRegistered<InventoryController>()) {
                                            final inventoryController =
                                                Get.find<InventoryController>();
                                            await inventoryController
                                                .refreshCurrentView(
                                              showLoader: false,
                                            );
                                            inventoryController.scheduleRefresh(
                                              delay: const Duration(milliseconds: 400),
                                              showLoader: false,
                                            );
                                          }
                                          await ctrl.load();
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

  final itemNameCtrl = TextEditingController();
  String? selectedItemId;
  final qtyCtrl = TextEditingController(text: '1');
  final unitCtrl = TextEditingController(text: '0');
  final freightCtrl = TextEditingController(
    text: (original.freight ?? 0) > 0 ? original.freight!.toString() : '',
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

  await Get.find<PurchasesController>().ensureItemNamesLoaded();
  final names = Map<String, String>.from(
    Get.find<PurchasesController>().itemNames,
  );
  for (final it in items) {
    displayItems.add({
      'name': names[it.itemId] ?? it.itemId,
      'qty': it.qty,
      'unit': it.unitCost,
    });
  }

  Future<void> pickSupplier() async {
    final service = Get.find<SuppliersService>();
    final list = RxList<SupplierModel>(await service.list(text: ''));
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
              },
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
                          [
                            list[i].docNumber,
                            list[i].phone,
                          ].where((e) => (e ?? '').isNotEmpty).join(' - '),
                        ),
                        onTap: () {
                          supplierId.value = list[i].id;
                          supplierNameCtrl.text = list[i].name;
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
                  TextFormField(
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
                    decoration: const InputDecoration(
                      labelText: 'Fornecedor',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
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
                          keyboardType: TextInputType.number,
                          validator:
                              (v) => FormValidators.validateOptionalNumber(
                                v,
                                fieldName: 'Frete',
                                positive: true,
                              ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Frete (opcional)',
                            prefixText: 'R\$ ',
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
                            ),
                          );
                          displayItems.add({
                            'name': itemNameCtrl.text,
                            'qty': qty,
                            'unit': unit,
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
                          return ListTile(
                            dense: true,
                            title: Text(
                              it['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Qtd: ${it['qty']} - Unit: R\$ ${(it['unit'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                items.removeAt(i);
                                displayItems.removeAt(i);
                              },
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
                                      if (!formKey.currentState!.validate())
                                        return;
                                      final freight =
                                          freightCtrl.text.trim().isEmpty
                                              ? null
                                              : double.tryParse(
                                                freightCtrl.text
                                                    .trim()
                                                    .replaceAll(',', '.'),
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
                                      );
                                      if (updated != null &&
                                          status.value == 'received' &&
                                          original.status.toLowerCase() !=
                                              'received') {
                                        await ctrl.receive(
                                          updated.id,
                                          receivedAt: DateTime.now(),
                                        );
                                      }
                                      await ctrl.load();
                                      Get.back();
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
