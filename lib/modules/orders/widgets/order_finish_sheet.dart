import 'dart:convert';

import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:air_sync/application/utils/formatters/money_formatter.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    required this.billingItems,
    required this.materialInputs,
    required this.payments,
    required this.totalDue,
    this.signatureBase64,
    this.notes,
    this.discount,
  });

  final List<OrderBillingItemInput> billingItems;
  final List<OrderMaterialInput> materialInputs;
  final List<OrderPaymentInput> payments;
  final double totalDue;
  final String? signatureBase64;
  final String? notes;
  final num? discount;
}

class _MarginSummaryBanner extends StatelessWidget {
  const _MarginSummaryBanner({
    required this.revenue,
    required this.cost,
    required this.margin,
    this.marginPercent,
    this.title = 'Margem estimada da OS',
    this.showHelperText = true,
  });

  final double revenue;
  final double cost;
  final double margin;
  final double? marginPercent;
  final String title;
  final bool showHelperText;

  @override
  Widget build(BuildContext context) {
    final marginColor =
        margin >= 0 ? Colors.greenAccent : Colors.redAccent;
    final helper =
        marginPercent != null ? '${marginPercent!.toStringAsFixed(1)}%' : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          if (showHelperText)
            const Text(
              'Baseado nos valores atuais retornados pela API.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MarginMetric(
                  label: 'Receita prevista',
                  value: formatCurrencyPtBr(revenue),
                  icon: Icons.trending_up_outlined,
                  background:
                      Colors.white.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MarginMetric(
                  label: 'Custo de materiais',
                  value: formatCurrencyPtBr(cost),
                  icon: Icons.inventory_2_outlined,
                  background: Colors.white10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MarginMetric(
                  label: 'Margem estimada',
                  value: formatCurrencyPtBr(margin),
                  icon: Icons.calculate_outlined,
                  background: marginColor.withValues(alpha: 0.18),
                  helper: helper,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarginMetric extends StatelessWidget {
  const _MarginMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                helper!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
            ? formatCurrencyPtBr(widget.order.billing.discount)
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
  bool _paymentsDirty = false;
  bool _suppressPaymentListeners = false;
  double? _lastAutoBalancedTotal;

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
      final materialCostSubtotal = _materials.fold<double>(
        0,
        (sum, draft) => sum + draft.lineCost,
      );
      final serviceSubtotal = _services.fold<double>(
        0,
        (sum, draft) => sum + draft.lineTotal,
      );
      final discountValue = parseCurrencyPtBr(_discountCtrl.text) ?? 0;
      var total = materialSubtotal + serviceSubtotal - discountValue;
      if (total < 0) total = 0;
      final marginValue = total - materialCostSubtotal;
      final paymentTotal = _payments.fold<double>(
        0,
        (sum, draft) => sum + (draft.amount ?? 0),
      );
      final paymentDifference = total - paymentTotal;
      final paymentBalanced = paymentDifference.abs() < 0.01;
      final paymentMessageColor =
          paymentBalanced
              ? Colors.white.withValues(alpha: 0.08)
              : (
                  paymentDifference > 0
                      ? Colors.orangeAccent.withValues(alpha: 0.18)
                      : Colors.greenAccent.withValues(alpha: 0.18)
                );
      final rawPixKey = widget.companyProfile?.pixKey;
      final pixKey = rawPixKey?.trim();
      final hasPixKey = pixKey?.isNotEmpty == true;
      final pixKeyLabel = pixKey ?? '';
      final currentError = _error.value;
      final isSubmitting = _submitting.value;
      final baselineRevenue = widget.order.billing.total.toDouble();
      final baselineCost = widget.order.materialsCostTotal;
      final baselineMargin = baselineRevenue - baselineCost;
      final baselineMarginPercent =
          baselineRevenue > 0 ? (baselineMargin / baselineRevenue) * 100 : null;
      final hasBaselineSummary =
          baselineRevenue > 0 || baselineCost > 0 || baselineMargin != 0;
      double baselineMaterialRevenue = 0;
      double baselineServiceRevenue = 0;
      if (hasBaselineSummary && widget.order.billing.items.isNotEmpty) {
        for (final item in widget.order.billing.items) {
          final line = item.lineTotal.toDouble();
          final type = item.type.toLowerCase();
          if (type == 'part') {
            baselineMaterialRevenue += line;
          } else if (type == 'service') {
            baselineServiceRevenue += line;
          }
        }
      }
      final materialsHelper =
          hasBaselineSummary
              ? _deltaHelper(baselineMaterialRevenue, materialSubtotal)
              : null;
      final servicesHelper =
          hasBaselineSummary
              ? _deltaHelper(baselineServiceRevenue, serviceSubtotal)
              : null;
      final costHelper =
          hasBaselineSummary
              ? _deltaHelper(baselineCost, materialCostSubtotal)
              : null;
      final totalHelper =
          hasBaselineSummary ? _deltaHelper(baselineRevenue, total) : null;

      final shouldAutoBalance =
          !_paymentsDirty &&
          (_lastAutoBalancedTotal == null ||
              (total - _lastAutoBalancedTotal!).abs() > 0.01);
      if (shouldAutoBalance) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _autoBalancePayments(total),
        );
      }

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
                  if (hasBaselineSummary) ...[
                    _MarginSummaryBanner(
                      title: 'Margem original',
                      revenue: baselineRevenue,
                      cost: baselineCost,
                      margin: baselineMargin,
                      marginPercent: baselineMarginPercent,
                    ),
                    const SizedBox(height: 12),
                  ],
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
                                          () => _removeMaterial(entry.key),
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
                                  helper: materialsHelper,
                                ),
                                if (materialCostSubtotal > 0)
                                  _SummaryRow(
                                    label: 'Custo estimado (materiais)',
                                    value: materialCostSubtotal,
                                    helper: costHelper,
                                  ),
                                _SummaryRow(
                                  label: 'Serviços',
                                  value: serviceSubtotal,
                                  helper: servicesHelper,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _discountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [MoneyInputFormatter()],
                                  decoration: const InputDecoration(
                                    labelText: 'Desconto',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _SummaryRow(
                                  label: 'Total',
                                  value: total,
                                  emphasize: true,
                                  helper: totalHelper,
                                ),
                                if (materialCostSubtotal > 0) ...[
                                  const SizedBox(height: 12),
                                  _MarginSummaryBanner(
                                    title: 'Margem desta finalização',
                                    revenue: total,
                                    cost: materialCostSubtotal,
                                    margin: marginValue,
                                    marginPercent:
                                        total > 0
                                            ? (marginValue / total) * 100
                                            : null,
                                    showHelperText: false,
                                  ),
                                  if (marginValue < 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Atenção: margem negativa. Revise preços ou descontos antes de concluir.',
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
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
                                      'PIX cadastrado: $pixKeyLabel',
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
                                    pixKey: pixKey,
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
                                }),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: paymentMessageColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  child: Text(
                                    paymentBalanced
                                        ? 'Pagamentos somam ${formatCurrencyPtBr(paymentTotal)}.'
                                        : paymentDifference > 0
                                        ? 'Faltam ${formatCurrencyPtBr(paymentDifference)}.'
                                        : 'Sobram ${formatCurrencyPtBr(paymentDifference.abs())}.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
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
    final billingItems = order.billing.items;
    final materialKeys = <String>{};

    String keyForMaterial({String? name, String? itemId}) {
      final normalizedName = (name ?? '').trim().toLowerCase();
      if (normalizedName.isNotEmpty) return 'name:$normalizedName';
      final normalizedId = (itemId ?? '').trim().toLowerCase();
      if (normalizedId.isNotEmpty) return 'id:$normalizedId';
      return '';
    }

    if (order.materials.isNotEmpty) {
      for (final material in order.materials) {
        final draft = _FinishMaterialDraft(
          itemId: material.itemId,
          itemName: material.itemName ?? material.itemId,
          description: material.description,
          quantity: material.qty.toDouble(),
          unitPrice: _materialUnitPrice(material, billingItems),
          unitCost: material.unitCost,
        );
        drafts.add(draft);
        final key = keyForMaterial(name: draft.itemName, itemId: draft.itemId);
        if (key.isNotEmpty) {
          materialKeys.add(key);
        }
      }
    }

    for (final item in billingItems) {
      if (item.type != 'part') continue;
      final key = keyForMaterial(name: item.name);
      if (key.isNotEmpty && materialKeys.contains(key)) continue;
      drafts.add(
        _FinishMaterialDraft(
          itemName: item.name,
          description: item.name,
          quantity: item.qty.toDouble(),
          unitPrice: item.unitPrice.toDouble(),
          unitCost: null,
        ),
      );
    }

    if (drafts.isEmpty) drafts.add(_FinishMaterialDraft());
    return drafts;
  }

  double? _materialUnitPrice(
    OrderMaterialItem material,
    List<OrderBillingItem> billingItems,
  ) {
    if (material.unitPrice != null) return material.unitPrice;
    final materialName = material.itemName?.trim().toLowerCase();
    if (materialName == null || materialName.isEmpty) return null;
    for (final item in billingItems) {
      if (item.type != 'part') continue;
      if (item.name.trim().toLowerCase() == materialName) {
        return item.unitPrice.toDouble();
      }
    }
    return null;
  }

  String? _deltaHelper(double baseline, double current) {
    const tolerance = 0.01;
    final diff = current - baseline;
    if (diff.abs() < tolerance) return null;
    final prefix = diff > 0 ? '+ ' : '- ';
    return 'Variação vs. original: $prefix${formatCurrencyPtBr(diff.abs())}';
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
    if (_materials.isEmpty) {
      final replacement = _FinishMaterialDraft();
      _materials.add(replacement);
      _attachMaterialDraft(replacement);
    }
    _handleDraftChanged();
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
    _paymentsDirty = true;
    _handleDraftChanged();
  }

  void _removePayment(int index) {
    if (_payments.length <= 1) return;
    final draft = _payments.removeAt(index);
    _detachPaymentDraft(draft);
    draft.dispose();
    _paymentsDirty = true;
    _handleDraftChanged();
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
    target.amountCtrl.text = formatCurrencyPtBr(remainder);
    _handleDraftChanged();
  }

  void _attachPaymentDraft(_FinishPaymentDraft draft) {
    draft.amountListener = () => _onPaymentDraftEdited();
    draft.installmentsListener = () => _onPaymentDraftEdited();
    draft.methodListener = () => _onPaymentDraftEdited();
    draft.amountCtrl.addListener(draft.amountListener!);
    draft.installmentsCtrl.addListener(draft.installmentsListener!);
    draft.methodNotifier.addListener(draft.methodListener!);
  }

  void _detachPaymentDraft(_FinishPaymentDraft draft) {
    if (draft.amountListener != null) {
      draft.amountCtrl.removeListener(draft.amountListener!);
      draft.amountListener = null;
    }
    if (draft.installmentsListener != null) {
      draft.installmentsCtrl.removeListener(draft.installmentsListener!);
      draft.installmentsListener = null;
    }
    if (draft.methodListener != null) {
      draft.methodNotifier.removeListener(draft.methodListener!);
      draft.methodListener = null;
    }
  }

  void _handleDraftChanged() {
    if (mounted) {
      _rebuildTick.value++;
    }
  }

  void _onPaymentDraftEdited() {
    if (_suppressPaymentListeners) {
      return;
    }
    _paymentsDirty = true;
    _handleDraftChanged();
  }

  double _currentPaymentTotal() =>
      _payments.fold<double>(0, (sum, draft) => sum + (draft.amount ?? 0));

  void _autoBalancePayments(double total) {
    if (!mounted) return;
    const tolerance = 0.01;
    _suppressPaymentListeners = true;
    if (_payments.isEmpty) {
      final draft = _FinishPaymentDraft(
        method: 'PIX',
        amount: total > 0 ? total : 0,
      );
      _payments.add(draft);
      _attachPaymentDraft(draft);
    } else {
      final current = _currentPaymentTotal();
      final difference = total - current;
      if (difference.abs() > tolerance) {
        final target = _payments.last;
        var adjusted = (target.amount ?? 0) + difference;
        if (adjusted < 0) adjusted = 0;
        target.amountCtrl.text = formatCurrencyPtBr(adjusted);
      }
    }
    _suppressPaymentListeners = false;
    _lastAutoBalancedTotal = total;
    _handleDraftChanged();
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

  Future<void> _submit() async {
    final requiresSignature = widget.order.customerSignatureUrl == null;
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
        final draftDescription = (draft.description ?? '').trim();
        materialInputs.add(
          OrderMaterialInput(
            itemId: draft.itemId!,
            qty: qty,
            itemName: draftName.isEmpty ? null : draftName,
            description:
                draftDescription.isEmpty
                    ? (draftName.isEmpty ? null : draftName)
                    : draftDescription,
            unitPrice: price,
            unitCost: draft.unitCost,
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

    final discount = parseCurrencyPtBr(_discountCtrl.text) ?? 0;
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
      if (totalDue.abs() <= tolerance) {
        payments.add(OrderPaymentInput(method: 'PIX', amount: 0));
      } else {
        _error.value = 'Adicione ao menos um pagamento.';
        return;
      }
    }
    if ((paymentSum - totalDue).abs() > tolerance) {
      final difference = totalDue - paymentSum;
      final prefix = difference > 0 ? 'Faltam' : 'Sobram';
      final differenceLabel = formatCurrencyPtBr(difference.abs());
      _error.value = '$prefix $differenceLabel para fechar os pagamentos.';
      return;
    }

    Uint8List? data;
    if (_signatureController.isEmpty) {
      if (requiresSignature) {
        _error.value = 'Coleta de assinatura obrigatória.';
        return;
      }
    } else {
      data = await _signatureController.toPngBytes();
      if (data == null || data.isEmpty) {
        _error.value = 'Não foi possível capturar a assinatura.';
        return;
      }
    }

    _submitting.value = true;
    try {
      final base64Signature = data != null ? base64Encode(data) : null;
      _error.value = null;
      if (!mounted) return;
      Navigator.of(context).pop(
        OrderFinishResult(
          signatureBase64: base64Signature,
          billingItems: billingItems,
          materialInputs: materialInputs,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          discount: discount,
          payments: payments,
          totalDue: totalDue,
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
    this.itemId,
    this.itemName,
    this.description,
    double? quantity,
    double? unitPrice,
    this.unitCost,
  }) : qtyCtrl = TextEditingController(
         text:
             quantity != null
                 ? quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2)
                 : '',
       ),
       unitPriceCtrl = TextEditingController(
         text: unitPrice != null ? formatCurrencyPtBr(unitPrice) : '',
       );

  String? itemId;
  String? itemName;
  String? description;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;
  double? unitCost;
  double? stockQuantity;
  String? stockUnit;

  bool get hasContent =>
      (itemId != null && (quantity ?? 0) > 0) ||
      (itemName != null && itemName!.trim().isNotEmpty);

  double? get quantity {
    final value = qtyCtrl.text.replaceAll(',', '.').trim();
    return double.tryParse(value);
  }

  double? get unitPrice => parseCurrencyPtBr(unitPriceCtrl.text);

  double get lineTotal => (quantity ?? 0) * (unitPrice ?? 0);
  double get lineCost => (quantity ?? 0) * (unitCost ?? 0);

  String get displayName =>
      (itemName ?? '').trim().isNotEmpty
          ? itemName!.trim()
          : (itemId ?? 'Material');

  void setInventoryItem(InventoryItemModel item) {
    itemId = item.id;
    final itemDescription = item.description.trim();
    final sku = item.sku.trim();
    itemName =
        itemDescription.isNotEmpty
            ? itemDescription
            : (sku.isNotEmpty ? sku : item.id);
    stockQuantity = item.quantity;
    stockUnit = item.unit;
    unitCost = item.avgCost;
    final rawDescription = item.description.trim();
    if (rawDescription.isNotEmpty) {
      description = rawDescription;
    }
    if (item.sellPrice != null) {
      unitPriceCtrl.text = formatCurrencyPtBr(item.sellPrice!);
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
    description = null;
    unitCost = null;
    unitPriceCtrl.text = '';
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
        text: unitPrice != null ? formatCurrencyPtBr(unitPrice) : '',
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

  double? get unitPrice => parseCurrencyPtBr(unitPriceCtrl.text);

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
  });

  final _FinishMaterialDraft draft;
  final VoidCallback onPick;
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
              Expanded(
                child: Text(
                  draft.displayName,
                  style: TextStyle(
                    color: context.themeTextMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  : 'Trocar item',
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
                  inputFormatters: [MoneyInputFormatter()],
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
                  inputFormatters: [MoneyInputFormatter()],
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
        text: amount != null ? formatCurrencyPtBr(amount) : '',
      ),
      installmentsCtrl = TextEditingController(
        text: installments?.toString() ?? '',
      );

  final ValueNotifier<String> methodNotifier;
  final TextEditingController amountCtrl;
  final TextEditingController installmentsCtrl;
  VoidCallback? amountListener;
  VoidCallback? installmentsListener;
  VoidCallback? methodListener;

  String get method => methodNotifier.value;

  double? get amount => parseCurrencyPtBr(amountCtrl.text);

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
    this.pixKey,
    this.onRemove,
    this.onFillWithRemaining,
  });

  final _FinishPaymentDraft draft;
  final CompanyProfileModel? profile;
  final String? pixKey;
  final VoidCallback? onRemove;
  final VoidCallback? onFillWithRemaining;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: draft.methodNotifier,
      builder: (context, method, _) {
        final showInstallments = method == 'CARD_CREDIT';
        final showPixQrButton =
            method == 'PIX' && (pixKey?.trim().isNotEmpty ?? false);
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
                      inputFormatters: [MoneyInputFormatter()],
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
              if (showPixQrButton)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showPixQr(context),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Mostrar QR Code'),
                  ),
                ),
              if (currentAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    feePercent > 0
                        ? 'Taxa estimada: ${feePercent.toStringAsFixed(2)}% (${formatCurrencyPtBr(feeValue)}) · Líquido ${formatCurrencyPtBr(netAmount)}'
                        : 'Líquido ${formatCurrencyPtBr(netAmount)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPixQr(BuildContext context) {
    final key = pixKey?.trim();
    if (key == null || key.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('PIX'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: QrImageView(data: key, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 12),
              SelectableText(key, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
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
    final sectionColor = context.themeSurfaceAlt.withValues(alpha: 0.9);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sectionColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.helper,
  });

  final String label;
  final double value;
  final bool emphasize;
  final String? helper;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrencyPtBr(value), style: style),
              if (helper != null)
                Text(
                  helper!,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
            ],
          ),
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

