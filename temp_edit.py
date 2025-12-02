# -*- coding: utf-8 -*-
from pathlib import Path
path = Path('lib/modules/inventory/inventory_page.dart')
text = path.read_text(encoding='utf-8')
start = text.find('static Future<void> _showEditItemModal(')
end = text.find('\n  static Future<void> _confirmDeleteItem', start)
if start == -1 or end == -1:
    raise SystemExit('markers not found')
new_block = '''static Future<void> _showEditItemModal(
    BuildContext context,
    InventoryController c,
    InventoryItemModel item,
  ) async {
    String formatOptionalNumber(double? value) {
      if (value == null) return '';
      return value == value.roundToDouble()
          ? value.toStringAsFixed(0).replaceAll('.', ',')
          : value.toStringAsFixed(2).replaceAll('.', ',');
    }

    String formatOptionalMoney(double? value) {
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

    if (!context.mounted) return;
    final nameController = TextEditingController(text: item.description);
    final skuController = TextEditingController(text: item.sku);
    final unitController = TextEditingController(text: item.unit);
    final minController = TextEditingController(
      text: _formatQuantity(item.minQuantity),
    );
    final maxQtyController = TextEditingController(
      text: formatOptionalNumber(item.maxQuantity),
    );
    final costController = TextEditingController(
      text: formatOptionalMoney(item.avgCost),
    );
    final sellPriceController = TextEditingController(
      text: formatOptionalMoney(item.sellPrice),
    );
    final supplierManualController = TextEditingController(
      text: item.supplierId ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: false,
      builder: (sheetCtx) {
        final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Obx(() {
          final current = currentItem.value;
          final supplierValue = selectedSupplierId.value ?? '';
          return _InventoryModalShell(
            title: 'Editar item',
            subtitle:
                'Estoque atual: ${_formatQuantity(current.quantity)} ${current.unit}',
            onClose: () => Navigator.of(sheetCtx, rootNavigator: true).pop(),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Informe o nome do item'
                                : null,
                        decoration: const InputDecoration(labelText: 'Nome do item'),
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
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: unitController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Unidade',
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
                                if (sanitized.isEmpty) return null;
                                final number = double.tryParse(sanitized);
                                if (number == null || number < 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Quantidade mínima',
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
                              controller: maxQtyController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Estoque máximo (opcional)',
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
                              decoration: const InputDecoration(
                                labelText: 'Custo médio (opcional)',
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
                        decoration: const InputDecoration(
                          labelText: 'Preço de venda (opcional)',
                          prefixText: 'R$ ',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        dropdownColor: sheetCtx.themeSurface,
                        value: supplierValue.isEmpty ? null : supplierValue,
                        items: suppliers
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => selectedSupplierId.value = value,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        decoration: const InputDecoration(
                          labelText: 'Fornecedor (opcional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: supplierManualController,
                        decoration: const InputDecoration(
                          labelText: 'Fornecedor (manual)',
                          helperText:
                              'Use este campo se o cadastro de fornecedores estiver indisponível.',
                        ),
                      ),
                      if (current.costHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Histórico de custo (últimos registros)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...current.costHistory.take(3).map(
                          (entry) => Text(
                            '- R$ ${entry.cost.toStringAsFixed(2)} em ${entry.at.day.toString().padLeft(2, '0')}/${entry.at.month.toString().padLeft(2, '0')}/${entry.at.year}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sheetCtx.themeGreen,
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
                            unit: unitController.text.trim().isEmpty
                                ? item.unit
                                : unitController.text.trim(),
                            minQuantity: minQty,
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
                          if (!sheetCtx.mounted) return;
                          if (success &&
                              Navigator.of(sheetCtx, rootNavigator: true).canPop()) {
                            Navigator.of(sheetCtx, rootNavigator: true).pop();
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text(
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
            ),
          );
        });
      },
    );
  }
'''
new_text = text[:start] + new_block + text[end:]
path.write_text(new_text, encoding='utf-8')
