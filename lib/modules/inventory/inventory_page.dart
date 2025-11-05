import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/supplier_model.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum _InventoryStatus { ok, warning, danger }

class InventoryPage extends GetView<InventoryController> {
  const InventoryPage({super.key});

  static Future<void> showAddItemModal({required BuildContext context}) async {
    final c = Get.find<InventoryController>();
    await _showAddItemModal(context, c);
  }

  @override
  Widget build(BuildContext context) {
    controller.ensureLatestData(showLoader: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Estoque', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: () => controller.getItems(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => showAddItemModal(context: context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        final items = controller.items;
        final loading = controller.isLoading.value;

        return Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchField(context),
            ),
            if (loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: RefreshIndicator(
                color: context.themePrimary,
                backgroundColor: context.themeSurface,
                onRefresh:
                    () => controller.refreshCurrentView(showLoader: false),
                child:
                    items.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 140),
                            Center(
                              child: Text(
                                'Nenhum item encontrado',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          physics: const AlwaysScrollableScrollPhysics(),
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildItemCard(context, item);
                          },
                        ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Obx(() {
      final hasText = controller.searchTerm.value.isNotEmpty;
      return TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar item por nome ou SKU',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon:
              hasText
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      controller.searchController.clear();
                      controller.onSearchChanged('');
                    },
                  )
                  : null,
          filled: true,
          fillColor: context.themeSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: context.themeBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: context.themeBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: context.themePrimary),
          ),
        ),
      );
    });
  }

  Widget _buildItemCard(BuildContext context, InventoryItemModel item) {
    final status = _statusFor(item);
    final baseColor = context.themeSurface;
    Color backgroundColor = baseColor;
    Color borderColor = context.themeBorder;
    Color? badgeColor;
    IconData? badgeIcon;
    String? badgeLabel;

    if (status == _InventoryStatus.danger) {
      backgroundColor = Color.alphaBlend(
        Colors.redAccent.withOpacity(0.12),
        baseColor,
      );
      borderColor = Colors.redAccent.withOpacity(0.7);
      badgeColor = Colors.redAccent.withOpacity(0.2);
      badgeIcon = Icons.warning_amber_rounded;
      badgeLabel = 'Abaixo do mínimo';
    } else if (status == _InventoryStatus.warning) {
      backgroundColor = Color.alphaBlend(
        context.themeWarning.withOpacity(0.12),
        baseColor,
      );
      borderColor = context.themeWarning;
      badgeColor = context.themeWarning.withOpacity(0.2);
      badgeIcon = Icons.remove_red_eye_outlined;
      badgeLabel = 'Próximo do mínimo';
    }

    final badges = <Widget>[];
    if (badgeLabel != null && badgeColor != null && badgeIcon != null) {
      badges.add(
        _buildStatusChip(text: badgeLabel, color: badgeColor, icon: badgeIcon),
      );
    }
    if (!item.active) {
      badges.add(
        _buildStatusChip(
          text: 'Inativo',
          color: Colors.white12,
          icon: Icons.pause_circle_outline,
          textColor: Colors.white70,
        ),
      );
    }

    final quantityText =
        '${_formatQuantity(item.quantity)} ${item.unit.toUpperCase()}';
    final minText = _formatQuantity(item.minQuantity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditItemModal(context, controller, item),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: context.shadowCard,
          ),
          child: Padding(
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
                            item.description.isEmpty
                                ? 'Item sem nome'
                                : item.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${item.sku.isEmpty ? '-' : item.sku}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'history':
                            Get.toNamed('/inventory/item', arguments: item);
                            break;
                          case 'edit':
                            _showEditItemModal(context, controller, item);
                            break;
                          case 'delete':
                            _confirmDeleteItem(context, controller, item);
                            break;
                        }
                      },
                      color: context.themeSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder:
                          (ctx) => [
                            PopupMenuItem(
                              value: 'history',
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.history,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Histórico',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Editar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Estoque: $quantityText',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Mínimo: $minText',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (badges.isNotEmpty)
                  Wrap(spacing: 8, runSpacing: 8, children: badges),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showAddItemModal(
    BuildContext context,
    InventoryController c,
  ) async {
    c.clearForm();
    List<SupplierModel> suppliers = [];
    if (Get.isRegistered<SuppliersService>()) {
      try {
        suppliers = await Get.find<SuppliersService>().list(text: '');
      } catch (_) {
        suppliers = [];
      }
    }

    final formKey = GlobalKey<FormState>();
    if (c.unitController.text.isEmpty) {
      c.unitController.text = 'UN';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: false,
      useRootNavigator: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cadastrar item',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          c.clearForm();
                          Navigator.of(sheetCtx, rootNavigator: true).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: c.descriptionController,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome do item'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome do item',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: c.skuController,
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o código/SKU'
                                : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Código/SKU',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: c.quantityController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Quantidade inicial (opcional)',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: c.unitController,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Unidade',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: c.barcodeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Código de barras (opcional)',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: c.maxQtyController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Estoque máximo (opcional)',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: c.minStockController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final text = (v ?? '').replaceAll(',', '.').trim();
                            final number = double.tryParse(text);
                            if (number == null) {
                              return 'Informe o estoque mínimo';
                            }
                            if (number < 0) {
                              return 'Valor inválido';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Estoque mínimo',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: c.costController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Custo médio (opcional)',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (suppliers.isNotEmpty)
                    DropdownButtonFormField<String>(
                      dropdownColor: context.themeSurface,
                      value:
                          c.supplierIdController.text.isEmpty
                              ? null
                              : c.supplierIdController.text,
                      items:
                          suppliers
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => c.supplierIdController.text = value ?? '',
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor (opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  if (suppliers.isNotEmpty) const SizedBox(height: 10),
                  TextFormField(
                    controller: c.sellPriceController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Preço de venda (opcional)',
                      prefixText: 'R\$ ',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeGreen,
                      foregroundColor: context.themeGray,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (Navigator.of(
                        sheetCtx,
                        rootNavigator: true,
                      ).canPop()) {
                        Navigator.of(sheetCtx, rootNavigator: true).pop();
                        await Future.delayed(const Duration(milliseconds: 50));
                      }
                      await c.registerItem();
                    },
                    child: const Text(
                      'Cadastrar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      c.clearForm();
                      Navigator.of(sheetCtx, rootNavigator: true).pop();
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showEditItemModal(
    BuildContext context,
    InventoryController c,
    InventoryItemModel item,
  ) async {
    String _formatOptionalNumber(double? value) {
      if (value == null) return '';
      return value == value.roundToDouble()
          ? value.toStringAsFixed(0).replaceAll('.', ',')
          : value.toStringAsFixed(2).replaceAll('.', ',');
    }

    String _formatOptionalMoney(double? value) {
      if (value == null) return '';
      return value.toStringAsFixed(2).replaceAll('.', ',');
    }

    double? parseNullableDouble(String text) {
      final normalized = text.trim().replaceAll(',', '.');
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }

    final Rx<InventoryItemModel> currentItem = item.obs;
    final RxnString selectedSupplierId = RxnString(
      (item.supplierId?.isEmpty ?? true) ? null : item.supplierId,
    );
    List<SupplierModel> suppliers = [];
    if (Get.isRegistered<SuppliersService>()) {
      try {
        suppliers = await Get.find<SuppliersService>().list(text: '');
      } catch (_) {}
    }

    final nameController = TextEditingController(text: item.description);
    final skuController = TextEditingController(text: item.sku);
    final unitController = TextEditingController(text: item.unit);
    final minController = TextEditingController(
      text: _formatQuantity(item.minQuantity),
    );
    final barcodeController = TextEditingController(text: item.barcode ?? '');
    final maxQtyController = TextEditingController(
      text: _formatOptionalNumber(item.maxQuantity),
    );
    final costController = TextEditingController(
      text: _formatOptionalMoney(item.avgCost),
    );
    final sellPriceController = TextEditingController(
      text: _formatOptionalMoney(item.sellPrice),
    );
    final supplierManualController = TextEditingController(
      text: item.supplierId ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      useRootNavigator: true,
      isDismissible: false,
      builder: (sheetCtx) {
        return Obx(() {
          final current = currentItem.value;
          final supplierValue = selectedSupplierId.value ?? '';
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Editar item',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(sheetCtx, rootNavigator: true).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Estoque atual: ${_formatQuantity(current.quantity)} ${current.unit}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Informe o nome do item'
                                  : null,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nome do item',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: skuController,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      style: const TextStyle(color: Colors.white70),
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        helperText: 'Edição não permitida neste fluxo.',
                        helperStyle: TextStyle(color: Colors.white38),
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: unitController,
                            style: const TextStyle(color: Colors.white),
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Unidade',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: minController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final sanitized =
                                  (value ?? '').replaceAll(',', '.').trim();
                              final number = double.tryParse(sanitized);
                              if (number == null) return 'Informe o mínimo';
                              if (number < 0) return 'Valor inválido';
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Quantidade mínima',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: barcodeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Código de barras (opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: maxQtyController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final parsed = double.tryParse(
                                text.replaceAll(',', '.'),
                              );
                              if (parsed == null) return 'Valor inválido';
                              if (parsed < 0) return 'Deve ser positivo';
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Estoque máximo (opcional)',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: costController,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Custo médio (opcional)',
                              prefixText: 'R\$ ',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: sellPriceController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Preço de venda (opcional)',
                        prefixText: 'R\$ ',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (suppliers.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: supplierValue,
                        dropdownColor: context.themeSurface,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text(
                              'Sem fornecedor',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          ...suppliers.map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          selectedSupplierId.value =
                              (value == null || value.isEmpty) ? null : value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Fornecedor (opcional)',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                      )
                    else
                      TextFormField(
                        controller: supplierManualController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Fornecedor (ID opcional)',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final busy = c.isLoading.value;
                      final isDisabled = busy || current.quantity <= 0;
                      return OutlinedButton.icon(
                        onPressed:
                            isDisabled
                                ? null
                                : () async {
                                  final updated = await c.zeroItemStock(
                                    current,
                                  );
                                  if (updated != null) {
                                    currentItem.value = updated;
                                  }
                                },
                        icon:
                            busy
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.themePrimary,
                                    ),
                                  ),
                                )
                                : const Icon(Icons.inventory_2_outlined),
                        label: Text(
                          current.quantity <= 0
                              ? 'Estoque já está zerado'
                              : 'Zerar estoque',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: context.themePrimary),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themePrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final minQty =
                            double.tryParse(
                              minController.text.replaceAll(',', '.'),
                            ) ??
                            item.minQuantity;
                        final barcodeText = barcodeController.text.trim();
                        final maxQty = parseNullableDouble(
                          maxQtyController.text,
                        );
                        final avgCost = parseNullableDouble(
                          costController.text,
                        );
                        final sellPrice = parseNullableDouble(
                          sellPriceController.text,
                        );
                        final supplierValueToSave =
                            suppliers.isNotEmpty
                                ? selectedSupplierId.value
                                : (supplierManualController.text.trim().isEmpty
                                    ? null
                                    : supplierManualController.text.trim());
                        final updatedItem = item.copyWith(
                          description: nameController.text.trim(),
                          unit:
                              unitController.text.trim().isEmpty
                                  ? item.unit
                                  : unitController.text.trim(),
                          minQuantity: minQty,
                          barcode:
                              barcodeText.isEmpty ? item.barcode : barcodeText,
                          maxQuantity: maxQty ?? item.maxQuantity,
                          supplierId: supplierValueToSave ?? item.supplierId,
                          avgCost: avgCost ?? item.avgCost,
                          sellPrice: sellPrice ?? item.sellPrice,
                          active: item.active,
                        );
                        final success = await c.updateItem(
                          original: item,
                          updated: updatedItem,
                        );
                        if (success &&
                            Navigator.of(
                              sheetCtx,
                              rootNavigator: true,
                            ).canPop()) {
                          Navigator.of(sheetCtx, rootNavigator: true).pop();
                        }
                      },
                      child: const Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    nameController.dispose();
    skuController.dispose();
    unitController.dispose();
    minController.dispose();
    barcodeController.dispose();
    maxQtyController.dispose();
    costController.dispose();
    sellPriceController.dispose();
    supplierManualController.dispose();
  }

  static Future<void> _confirmDeleteItem(
    BuildContext context,
    InventoryController c,
    InventoryItemModel item,
  ) async {
    if (item.quantity > 0) {
      final goToEdit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogCtx) => AlertDialog(
              backgroundColor: dialogCtx.themeSurface,
              title: const Text(
                'Estoque em uso',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'O item ainda possui ${_formatQuantity(item.quantity)} ${item.unit}. '
                'Zere o estoque antes de concluir a exclusão.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogCtx.themePrimary,
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: const Text('Abrir edição'),
                ),
              ],
            ),
      );
      if (goToEdit == true) {
        await _showEditItemModal(context, c, item);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor: dialogCtx.themeSurface,
            title: const Text(
              'Excluir item',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Tem certeza de que deseja excluir '
              '"${item.description.isEmpty ? item.sku : item.description}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await c.deleteItem(item.id);
    }
  }

  static _InventoryStatus _statusFor(InventoryItemModel item) {
    final min = item.minQuantity;
    final qty = item.quantity;
    if (min > 0 && qty <= min) {
      return _InventoryStatus.danger;
    }
    if (min > 0 && qty <= min * 1.3) {
      return _InventoryStatus.warning;
    }
    return _InventoryStatus.ok;
  }

  static String _formatQuantity(double value) {
    final rounded =
        value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2);
    return rounded.replaceAll('.', ',');
  }

  Widget _buildStatusChip({
    required String text,
    required Color color,
    required IconData icon,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor ?? Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
