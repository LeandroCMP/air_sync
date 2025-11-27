import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/finance_reconciliation_model.dart';
import 'package:air_sync/modules/finance/finance_reconciliation_controller.dart';
import 'package:air_sync/modules/orders/order_detail_bindings.dart';
import 'package:air_sync/modules/orders/order_detail_page.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FinanceReconciliationPage extends StatelessWidget {
  const FinanceReconciliationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<FinanceReconciliationController>(
      init: FinanceReconciliationController(),
      builder: (controller) {
        final payments = controller.payments;
        final issues = controller.issues;
        final loading = controller.loading.value;
        final scope = controller.scope.value;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reconciliação'),
            backgroundColor: context.themeSurface,
          ),
          body: RefreshIndicator(
            color: context.themePrimary,
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  children: controller.scopes
                      .map(
                        (value) => ChoiceChip(
                          label: Text(
                            value == 'all'
                                ? 'Tudo'
                                : value == 'orders'
                                ? 'OS'
                                : 'Compras',
                          ),
                          selected: scope == value,
                          onSelected: (_) => controller.setScope(value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (controller.error.isNotEmpty)
                  _FeedbackCard(
                    icon: Icons.warning_amber_rounded,
                    message: controller.error.value,
                    onRetry: controller.load,
                  )
                else ...[
                  _ReconciliationSection(
                    title: 'Pagamentos analisados',
                    children: payments
                        .map((payment) => _PaymentTile(payment: payment))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _ReconciliationSection(
                    title: 'Sugestões e correções',
                    children:
                        issues.isEmpty
                            ? [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Nenhuma inconsistência encontrada.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ]
                            : issues
                                .map(
                                  (issue) => _IssueTile(
                                    issue: issue,
                                  ),
                                )
                                .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 32),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ],
      ),
    );
  }
}

class _ReconciliationSection extends StatelessWidget {
  const _ReconciliationSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final FinanceReconciliationPayment payment;
  static final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  Color _statusColor(BuildContext context) {
    if (!payment.hasIssue) return context.themePrimary;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final difference = payment.difference;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.themeSurfaceAlt,
      child: ListTile(
        title: Text(payment.reference, style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esperado: ${_currency.format(payment.expectedAmount)} | Pago: ${_currency.format(payment.paidAmount)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (payment.dueDate != null)
              Text(
                'Venc.: ${DateFormat('dd/MM/yyyy').format(payment.dueDate!.toLocal())}',
                style: TextStyle(color: context.themeTextSubtle, fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency.format(difference),
              style: TextStyle(
                color: _statusColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              payment.scope == 'orders' ? 'OS' : payment.scope == 'purchases' ? 'Compra' : 'Geral',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final FinanceReconciliationIssue issue;
  static final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final delta = issue.deltaAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.themeSurfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                  color: context.themePrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    issue.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openReference(issue),
                  child: const Text('Ver detalhe'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((issue.suggestion).trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                issue.suggestion,
                style: TextStyle(color: context.themeTextSubtle),
              ),
            ],
            if (delta != null) ...[
              const SizedBox(height: 4),
              Text(
                'Delta: ${_currency.format(delta)}',
                style: TextStyle(
                  color: delta >= 0 ? Colors.redAccent : Colors.lightBlueAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openReference(FinanceReconciliationIssue issue) {
    final reference = issue.reference.isNotEmpty ? issue.reference : issue.id;
    final lower = issue.type.toLowerCase();
    if (lower.contains('order')) {
      Get.to<OrderModel?>(
        () => const OrderDetailPage(),
        binding: OrderDetailBindings(orderId: reference),
      );
    } else {
      Get.toNamed('/purchases', arguments: {'initialFilter': reference});
    }
  }
}
