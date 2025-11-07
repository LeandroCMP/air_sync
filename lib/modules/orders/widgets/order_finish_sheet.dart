import 'dart:convert';

import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

import '../../../application/ui/theme_extensions.dart';

const _paymentMethodOptions = [
  _PaymentMethodOption('PIX', 'PIX'),
  _PaymentMethodOption('CASH', 'Dinheiro'),
  _PaymentMethodOption('CARD_CREDIT', 'Cartão de crédito'),
  _PaymentMethodOption('CARD_DEBIT', 'Cartão de débito'),
  _PaymentMethodOption('CHEQUE', 'Cheque'),
];

class _PaymentMethodOption {
  const _PaymentMethodOption(this.value, this.label);
  final String value;
  final String label;
}

class OrderFinishResult {
  OrderFinishResult({
    required this.signatureBase64,
    required this.billingItems,
    required this.materialInputs,
    required this.payments,
    this.notes,
    this.discount,
  });

  final String signatureBase64;
  final List<OrderBillingItemInput> billingItems;
  final List<OrderMaterialInput> materialInputs;
  final List<OrderPaymentInput> payments;
  final String? notes;
  final num? discount;
}

Future<OrderFinishResult?> showOrderFinishSheet({
  required BuildContext context,
  required OrderModel order,
  required List<InventoryItemModel> inventoryItems,
  CompanyProfileModel? companyProfile,
}) {
  return showModalBottomSheet<OrderFinishResult>(
    context: context,
    isScrollControlled: true,
    builder:
        (_) => _FinishOrderSheet(
          order: order,
          inventoryItems: inventoryItems,
          companyProfile: companyProfile,
        ),
  );
}

class _FinishOrderSheet extends StatefulWidget {
  const _FinishOrderSheet({
    required this.order,
    required this.inventoryItems,
    this.companyProfile,
  });

  final OrderModel order;
  final List<InventoryItemModel> inventoryItems;
  final CompanyProfileModel? companyProfile;

  @override
  State<_FinishOrderSheet> createState() => _FinishOrderSheetState();
}

class _FinishOrderSheetState extends State<_FinishOrderSheet> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );
  late final TextEditingController _notesCtrl = TextEditingController(
    text: widget.order.notes ?? '',
  );
  late final TextEditingController _discountCtrl = TextEditingController(
    text:
        widget.order.billing.discount > 0
            ? _formatCurrency(widget.order.billing.discount)
            : '',
  );
  late final RxList<_FinishMaterialDraft> _materials =
      _buildInitialMaterials(widget.order).obs;
  late final RxList<_FinishServiceDraft> _services =
      _buildInitialServices(widget.order).obs;
  late final RxList<_FinishPaymentDraft> _payments =
      _buildInitialPayments(widget.order).obs;
  final RxnString _error = RxnString();
  final RxBool _submitting = false.obs;
  final RxInt _rebuildTick = 0.obs;

  @override
  void initState() {
    super.initState();
    for (final draft in _materials) {
      _attachMaterialDraft(draft);
    }
    for (final draft in _services) {
      _attachServiceDraft(draft);
    }
    for (final draft in _payments) {
      _attachPaymentDraft(draft);
    }
    _discountCtrl.addListener(_handleDraftChanged);
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _notesCtrl.dispose();
    _discountCtrl.removeListener(_handleDraftChanged);
    _discountCtrl.dispose();
    for (final draft in _materials) {
      _detachMaterialDraft(draft);
      draft.dispose();
    }
    for (final draft in _services) {
      _detachServiceDraft(draft);
      draft.dispose();
    }
    for (final draft in _payments) {
      _detachPaymentDraft(draft);
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = _rebuildTick.value;
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      final materialSubtotal = _materials.fold<double>(
        0,
        (sum, draft) => sum + draft.lineTotal,
      );
      final serviceSubtotal = _services.fold<double>(
        0,
        (sum, draft) => sum + draft.lineTotal,
      );
      final discountValue = _parseCurrency(_discountCtrl.text) ?? 0;
      var total = materialSubtotal + serviceSubtotal - discountValue;
      if (total < 0) total = 0;
      final paymentTotal = _payments.fold<double>(
        0,
        (sum, draft) => sum + (draft.amount ?? 0),
      );
      final paymentDifference = total - paymentTotal;
      final paymentBalanced = paymentDifference.abs() < 0.01;
      final pixKey = widget.companyProfile?.pixKey.trim();
      final hasPixKey = pixKey != null && pixKey.isNotEmpty;
      final currentError = _error.value;
      final isSubmitting = _submitting.value;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.98,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Finalizar OS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SheetSection(
                            title: 'Materiais utilizados',
                            actionLabel: 'Adicionar material',
                            onAction: _addMaterialDraft,
                            child: Column(
                              children:
                                  _materials.asMap().entries.map((entry) {
                                    return _FinishMaterialCard(
                                      draft: entry.value,
                                      onPick:
                                          () => _pickInventoryItem(entry.value),
                                      onRemove:
                                          _materials.length == 1
                                              ? null
                                              : () =>
                                                  _removeMaterial(entry.key),
                                      onClearSelection:
                                          entry.value.itemId == null
                                              ? null
                                              : () => _clearMaterialSelection(
                                                entry.value,
                                              ),
                                    );
                                  }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SheetSection(
                            title: 'Serviços executados',
                            actionLabel: 'Adicionar serviço',
                            onAction: _addServiceDraft,
                            child: Column(
                              children:
                                  _services.asMap().entries.map((entry) {
                                    return _FinishServiceCard(
                                      draft: entry.value,
                                      onRemove:
                                          _services.length == 1
                                              ? null
                                              : () => _removeService(entry.key),
                                    );
                                  }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SheetSection(
                            title: 'Resumo financeiro',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SummaryRow(
                                  label: 'Materiais',
                                  value: materialSubtotal,
                                ),
                                _SummaryRow(
                                  label: 'Serviços',
                                  value: serviceSubtotal,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _discountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [_CurrencyInputFormatter()],
                                  decoration: const InputDecoration(
                                    labelText: 'Desconto',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _SummaryRow(
                                  label: 'Total',
                                  value: total,
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SheetSection(
                            title: 'Pagamentos',
                            actionLabel: 'Adicionar pagamento',
                            onAction: _addPaymentDraft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasPixKey)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'PIX cadastrado: ${pixKey!}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ..._payments.asMap().entries.map((entry) {
                                  return _FinishPaymentCard(
                                    draft: entry.value,
                                    profile: widget.companyProfile,
                                    onRemove:
                                        _payments.length == 1
                                            ? null
                                            : () => _removePayment(entry.key),
                                    onFillWithRemaining:
                                        () => _fillPaymentWithRemaining(
                                          entry.key,
                                          total,
                                        ),
                                  );
                                }).toList(),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    paymentBalanced
                                        ? 'Pagamentos somam ${_formatCurrency(paymentTotal)}.'
                                        : paymentDifference > 0
                                        ? 'Faltam ${_formatCurrency(paymentDifference)}.'
                                        : 'Sobram ${_formatCurrency(paymentDifference.abs())}.',
                                    style: TextStyle(
                                      color:
                                          paymentBalanced
                                              ? Colors.white70
                                              : (paymentDifference > 0
                                                  ? Colors.orangeAccent
                                                  : Colors.lightGreenAccent),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SheetSection(
                            title: 'Assinatura do cliente',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Signature(
                                    controller: _signatureController,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _signatureController.clear,
                                    child: const Text('Limpar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Observações',
                            ),
                          ),
                          if (currentError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              currentError,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : _submit,
                          icon:
                              isSubmitting
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.check_circle_outline),
                          label: const Text('Concluir OS'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  List<_FinishMaterialDraft> _buildInitialMaterials(OrderModel order) {
    final drafts = <_FinishMaterialDraft>[];
    for (final material in order.materials) {
      drafts.add(
        _FinishMaterialDraft(
          itemId: material.itemId,
          itemName: material.itemName ?? material.itemId,
          quantity: material.qty.toDouble(),
          unitPrice: material.unitPrice,
        ),
      );
    }
    for (final item in order.billing.items) {
      if (item.type == 'part') {
        drafts.add(
          _FinishMaterialDraft(
            itemName: item.name,
            quantity: item.qty.toDouble(),
            unitPrice: item.unitPrice.toDouble(),
          ),
        );
      }
    }
    if (drafts.isEmpty) drafts.add(_FinishMaterialDraft());
    return drafts;
  }

  List<_FinishServiceDraft> _buildInitialServices(OrderModel order) {
    final drafts =
        order.billing.items
            .where((item) => item.type == 'service')
            .map(
              (item) => _FinishServiceDraft(
                name: item.name,
                quantity: item.qty.toDouble(),
                unitPrice: item.unitPrice.toDouble(),
              ),
            )
            .toList();
    if (drafts.isEmpty) drafts.add(_FinishServiceDraft());
    return drafts;
  }

  List<_FinishPaymentDraft> _buildInitialPayments(OrderModel order) {
    if (order.payments.isEmpty) {
      final initialTotal = order.billing.total.toDouble();
      return [
        _FinishPaymentDraft(
          method: 'PIX',
          amount: initialTotal > 0 ? initialTotal : null,
        ),
      ];
    }
    return order.payments
        .map(
          (payment) => _FinishPaymentDraft(
            method: payment.method,
            amount: payment.amount,
            installments: payment.installments,
          ),
        )
        .toList();
  }

  void _addMaterialDraft() {
    final draft = _FinishMaterialDraft();
    _materials.add(draft);
    _attachMaterialDraft(draft);
  }

  void _removeMaterial(int index) {
    final draft = _materials.removeAt(index);
    _detachMaterialDraft(draft);
    draft.dispose();
  }

  void _addServiceDraft() {
    final draft = _FinishServiceDraft();
    _services.add(draft);
    _attachServiceDraft(draft);
  }

  void _removeService(int index) {
    final draft = _services.removeAt(index);
    _detachServiceDraft(draft);
    draft.dispose();
  }

  void _attachMaterialDraft(_FinishMaterialDraft draft) {
    draft.qtyCtrl.addListener(_handleDraftChanged);
    draft.unitPriceCtrl.addListener(_handleDraftChanged);
  }

  void _detachMaterialDraft(_FinishMaterialDraft draft) {
    draft.qtyCtrl.removeListener(_handleDraftChanged);
    draft.unitPriceCtrl.removeListener(_handleDraftChanged);
  }

  void _attachServiceDraft(_FinishServiceDraft draft) {
    draft.qtyCtrl.addListener(_handleDraftChanged);
    draft.unitPriceCtrl.addListener(_handleDraftChanged);
  }

  void _detachServiceDraft(_FinishServiceDraft draft) {
    draft.qtyCtrl.removeListener(_handleDraftChanged);
    draft.unitPriceCtrl.removeListener(_handleDraftChanged);
  }

  void _addPaymentDraft() {
    final draft = _FinishPaymentDraft();
    _payments.add(draft);
    _attachPaymentDraft(draft);
  }

  void _removePayment(int index) {
    if (_payments.length <= 1) return;
    final draft = _payments.removeAt(index);
    _detachPaymentDraft(draft);
    draft.dispose();
  }

  void _fillPaymentWithRemaining(int index, double total) {
    var others = 0.0;
    for (final entry in _payments.asMap().entries) {
      if (entry.key == index) continue;
      others += entry.value.amount ?? 0;
    }
    final remainder = total - others;
    if (remainder <= 0) return;
    final target = _payments[index];
    target.amountCtrl.text = _formatCurrency(remainder);
    _handleDraftChanged();
  }

  void _attachPaymentDraft(_FinishPaymentDraft draft) {
    draft.amountCtrl.addListener(_handleDraftChanged);
    draft.installmentsCtrl.addListener(_handleDraftChanged);
    draft.methodNotifier.addListener(_handleDraftChanged);
  }

  void _detachPaymentDraft(_FinishPaymentDraft draft) {
    draft.amountCtrl.removeListener(_handleDraftChanged);
    draft.installmentsCtrl.removeListener(_handleDraftChanged);
    draft.methodNotifier.removeListener(_handleDraftChanged);
  }

  void _handleDraftChanged() {
    if (mounted) {
      _rebuildTick.value++;
    }
  }

  Future<void> _pickInventoryItem(_FinishMaterialDraft draft) async {
    final picked = await _InventoryPicker.show(
      context: context,
      items: widget.inventoryItems,
      selectedId: draft.itemId,
    );
    if (picked == null) return;
    draft.setInventoryItem(picked);
    _materials.refresh();
    _handleDraftChanged();
  }

  void _clearMaterialSelection(_FinishMaterialDraft draft) {
    draft.clearInventorySelection();
    _materials.refresh();
    _handleDraftChanged();
  }

  Future<void> _submit() async {
    if (_signatureController.isEmpty) {
      _error.value = 'Coleta de assinatura obrigatória.';
      return;
    }

    final materialInputs = <OrderMaterialInput>[];
    final billingItems = <OrderBillingItemInput>[];

    for (final draft in _materials) {
      if (!draft.hasContent) continue;
      final qty = draft.quantity;
      if (qty == null || qty <= 0) {
        _error.value = 'Informe quantidade válida para os materiais.';
        return;
      }
      final name = draft.displayName;
      final price = draft.unitPrice ?? 0;
      billingItems.add(
        OrderBillingItemInput(
          type: 'part',
          name: name,
          qty: qty,
          unitPrice: price,
        ),
      );
      if (draft.itemId != null) {
        final draftName = (draft.itemName ?? '').trim();
        materialInputs.add(
          OrderMaterialInput(
            itemId: draft.itemId!,
            qty: qty,
            itemName: draftName.isEmpty ? null : draftName,
            description: draftName.isEmpty ? null : draftName,
          ),
        );
      }
    }

    for (final draft in _services) {
      if (!draft.hasContent) continue;
      final name = draft.name.trim();
      if (name.isEmpty) {
        _error.value = 'Informe o nome dos serviços.';
        return;
      }
      final qty = draft.quantity ?? 1;
      if (qty <= 0) {
        _error.value = 'Quantidade de serviços inválida.';
        return;
      }
      final price = draft.unitPrice ?? 0;
      billingItems.add(
        OrderBillingItemInput(
          type: 'service',
          name: name,
          qty: qty,
          unitPrice: price,
        ),
      );
    }

    final discount = _parseCurrency(_discountCtrl.text) ?? 0;
    final materialSubtotal = _materials.fold<double>(
      0,
      (sum, draft) => sum + draft.lineTotal,
    );
    final serviceSubtotal = _services.fold<double>(
      0,
      (sum, draft) => sum + draft.lineTotal,
    );
    var totalDue = materialSubtotal + serviceSubtotal - discount;
    if (totalDue < 0) totalDue = 0;

    final payments = <OrderPaymentInput>[];
    var paymentSum = 0.0;
    for (final draft in _payments) {
      final amount = draft.amount;
      if (amount == null || amount < 0) continue;
      var installments = draft.installments;
      if (draft.method == 'CARD_CREDIT') {
        if (installments == null || installments <= 0) {
          _error.value =
              'Informe o número de parcelas para pagamentos no cartão de crédito.';
          return;
        }
      } else {
        installments = null;
      }
      payments.add(
        OrderPaymentInput(
          method: draft.method,
          amount: amount,
          installments: installments,
        ),
      );
      paymentSum += amount;
    }

    const tolerance = 0.01;
    if (payments.isEmpty) {
      _error.value = 'Adicione ao menos um pagamento.';
      return;
    }
    if ((paymentSum - totalDue).abs() > tolerance) {
      final difference = totalDue - paymentSum;
      final prefix = difference > 0 ? 'Faltam' : 'Sobram';
      final differenceLabel = _formatCurrency(difference.abs());
      _error.value = '$prefix $differenceLabel para fechar os pagamentos.';
      return;
    }

    _submitting.value = true;
    try {
      final data = await _signatureController.toPngBytes();
      if (data == null || data.isEmpty) {
        _error.value = 'Não foi possível capturar a assinatura.';
        return;
      }
      final base64Signature = base64Encode(data);
      _error.value = null;
      Navigator.of(context).pop(
        OrderFinishResult(
          signatureBase64: base64Signature,
          billingItems: billingItems,
          materialInputs: materialInputs,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          discount: discount,
          payments: payments,
        ),
      );
    } finally {
      if (mounted) {
        _submitting.value = false;
      }
    }
  }
}

class _FinishMaterialDraft {
  _FinishMaterialDraft({
    String? itemId,
    String? itemName,
    double? quantity,
    double? unitPrice,
    this.stockQuantity,
    this.stockUnit,
  }) : itemId = itemId,
       itemName = itemName,
       qtyCtrl = TextEditingController(
         text:
             quantity != null
                 ? quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2)
                 : '',
       ),
       unitPriceCtrl = TextEditingController(
         text: unitPrice != null ? _formatCurrency(unitPrice) : '',
       );

  String? itemId;
  String? itemName;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;
  double? stockQuantity;
  String? stockUnit;

  bool get hasContent =>
      (itemId != null && (quantity ?? 0) > 0) ||
      (itemName != null && itemName!.trim().isNotEmpty);

  double? get quantity {
    final value = qtyCtrl.text.replaceAll(',', '.').trim();
    return double.tryParse(value);
  }

  double? get unitPrice => _parseCurrency(unitPriceCtrl.text);

  double get lineTotal => (quantity ?? 0) * (unitPrice ?? 0);

  String get displayName =>
      (itemName ?? '').trim().isNotEmpty
          ? itemName!.trim()
          : (itemId ?? 'Material');

  void setInventoryItem(InventoryItemModel item) {
    itemId = item.id;
    final description = item.description.trim();
    final sku = item.sku.trim();
    itemName =
        description.isNotEmpty ? description : (sku.isNotEmpty ? sku : item.id);
    stockQuantity = item.quantity;
    stockUnit = item.unit;
    if (item.sellPrice != null) {
      unitPriceCtrl.text = _formatCurrency(item.sellPrice!);
    }
    if ((quantity ?? 0) == 0) {
      qtyCtrl.text = '1';
    }
  }

  void clearInventorySelection() {
    itemId = null;
    stockQuantity = null;
    stockUnit = null;
    itemName = null;
  }

  void dispose() {
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }
}

class _FinishServiceDraft {
  _FinishServiceDraft({String? name, double? quantity, double? unitPrice})
    : nameCtrl = TextEditingController(text: name ?? ''),
      qtyCtrl = TextEditingController(
        text:
            quantity != null
                ? quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2)
                : '1',
      ),
      unitPriceCtrl = TextEditingController(
        text: unitPrice != null ? _formatCurrency(unitPrice) : '',
      );

  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;

  bool get hasContent => nameCtrl.text.trim().isNotEmpty;
  String get name => nameCtrl.text;
  double? get quantity {
    final value = qtyCtrl.text.replaceAll(',', '.').trim();
    return double.tryParse(value);
  }

  double? get unitPrice => _parseCurrency(unitPriceCtrl.text);

  double get lineTotal => (quantity ?? 0) * (unitPrice ?? 0);

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }
}

class _FinishMaterialCard extends StatelessWidget {
  const _FinishMaterialCard({
    required this.draft,
    required this.onPick,
    this.onRemove,
    this.onClearSelection,
  });

  final _FinishMaterialDraft draft;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.displayName,
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onClearSelection != null && draft.itemId != null)
                IconButton(
                  tooltip: 'Remover item selecionado',
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.white70,
                  onPressed: onClearSelection,
                ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.white70,
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(
              draft.itemId == null
                  ? 'Selecionar item do estoque'
                  : 'Alterar item',
            ),
          ),
          if (draft.stockQuantity != null || (draft.stockUnit ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Estoque atual: '
                '${draft.stockQuantity?.toStringAsFixed(2) ?? '--'} '
                '${draft.stockUnit ?? ''}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.unitPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor unitário',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinishServiceCard extends StatelessWidget {
  const _FinishServiceCard({required this.draft, this.onRemove});

  final _FinishServiceDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Serviço',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.white70,
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.nameCtrl,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.unitPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Valor unitário',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinishPaymentDraft {
  _FinishPaymentDraft({String? method, double? amount, int? installments})
    : methodNotifier = ValueNotifier<String>(method ?? 'PIX'),
      amountCtrl = TextEditingController(
        text: amount != null ? _formatCurrency(amount) : '',
      ),
      installmentsCtrl = TextEditingController(
        text: installments?.toString() ?? '',
      );

  final ValueNotifier<String> methodNotifier;
  final TextEditingController amountCtrl;
  final TextEditingController installmentsCtrl;

  String get method => methodNotifier.value;

  double? get amount => _parseCurrency(amountCtrl.text);

  int? get installments {
    final text = installmentsCtrl.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void setMethod(String value) {
    if (methodNotifier.value == value) return;
    methodNotifier.value = value;
    if (value != 'CARD_CREDIT') {
      installmentsCtrl.text = '';
    } else if (installmentsCtrl.text.trim().isEmpty) {
      installmentsCtrl.text = '1';
    }
  }

  double feePercentFor(CompanyProfileModel? profile) {
    if (profile == null) return 0;
    switch (method) {
      case 'CARD_CREDIT':
        final target = installments ?? 1;
        try {
          return profile.creditFees
              .firstWhere((fee) => fee.installments == target)
              .feePercent;
        } catch (_) {
          return 0;
        }
      case 'CARD_DEBIT':
        return profile.debitFeePercent;
      case 'CHEQUE':
        return profile.chequeFeePercent;
      default:
        return 0;
    }
  }

  double feeValueFor(CompanyProfileModel? profile) =>
      (amount ?? 0) * feePercentFor(profile) / 100;

  double netAmountFor(CompanyProfileModel? profile) =>
      (amount ?? 0) - feeValueFor(profile);

  void dispose() {
    methodNotifier.dispose();
    amountCtrl.dispose();
    installmentsCtrl.dispose();
  }
}

class _FinishPaymentCard extends StatelessWidget {
  const _FinishPaymentCard({
    required this.draft,
    required this.profile,
    this.onRemove,
    this.onFillWithRemaining,
  });

  final _FinishPaymentDraft draft;
  final CompanyProfileModel? profile;
  final VoidCallback? onRemove;
  final VoidCallback? onFillWithRemaining;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: draft.methodNotifier,
      builder: (context, method, _) {
        final showInstallments = method == 'CARD_CREDIT';
        final currentAmount = draft.amount ?? 0;
        final feePercent = draft.feePercentFor(profile);
        final feeValue = draft.feeValueFor(profile);
        final netAmount = draft.netAmountFor(profile);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.themeSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(labelText: 'Método'),
                      items:
                          _paymentMethodOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.value,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) =>
                              value == null ? null : draft.setMethod(value),
                    ),
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remover pagamento',
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.white70,
                      onPressed: onRemove,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_CurrencyInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Valor'),
                    ),
                  ),
                  if (showInstallments) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: draft.installmentsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Parcelas',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (onFillWithRemaining != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onFillWithRemaining,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Usar restante'),
                  ),
                ),
              if (currentAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    feePercent > 0
                        ? 'Taxa estimada: ${feePercent.toStringAsFixed(2)}% (${_formatCurrency(feeValue)}) · Líquido ${_formatCurrency(netAmount)}'
                        : 'Líquido ${_formatCurrency(netAmount)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (actionLabel != null && onAction != null)
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.white70,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(_formatCurrency(value), style: style),
        ],
      ),
    );
  }
}

class _InventoryPicker extends StatelessWidget {
  const _InventoryPicker({required this.items, this.selectedId});

  final List<InventoryItemModel> items;
  final String? selectedId;

  static Future<InventoryItemModel?> show({
    required BuildContext context,
    required List<InventoryItemModel> items,
    String? selectedId,
  }) async {
    return showModalBottomSheet<InventoryItemModel>(
      context: context,
      builder: (_) => _InventoryPicker(items: items, selectedId: selectedId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Nenhum item de estoque disponível.')),
      );
    }
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final item = items[index];
          final description = item.description.trim();
          final subtitle = [
            if (item.sku.trim().isNotEmpty) 'SKU: ${item.sku}',
            'Estoque: ${item.quantity.toStringAsFixed(2)} ${item.unit}',
          ].join(' · ');
          return ListTile(
            selected: item.id == selectedId,
            title: Text(description.isEmpty ? item.id : description),
            subtitle: Text(subtitle),
            onTap: () => Navigator.of(context).pop(item),
          );
        },
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = double.parse(digitsOnly) / 100;
    final text = _formatCurrency(value);
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

double? _parseCurrency(String? value) {
  if (value == null) return null;
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return double.parse(digits) / 100;
}

String _formatCurrency(num value) {
  final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return format.format(value);
}
