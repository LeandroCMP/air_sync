import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/models/subscription_models.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:intl/intl.dart';

const double _fixedPlanAmount = 120;
bool _isProratedInvoice(
  SubscriptionInvoiceModel invoice, {
  double? planAmount,
}) {
  final referenceAmount = planAmount ?? _fixedPlanAmount;
  return invoice.amountDue > 0.01 && invoice.amountDue < (referenceAmount - 0.01);
}

bool _isTrialInvoice(SubscriptionInvoiceModel invoice) =>
    invoice.amountDue <= 0.01;

class SubscriptionsPage extends GetView<SubscriptionsController> {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.themeBg,
        appBar: AppBar(
          title: const Text('Minha assinatura'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Atualizar dados',
              onPressed: controller.refreshAll,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Faturas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Obx(
              () => controller.isLoading.value
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(controller: controller),
                  _InvoicesTab(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String formatCurrency(double value, {String currency = 'BRL'}) {
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: currency.toUpperCase() == 'BRL' ? 'R\$' : currency,
    );
    return fmt.format(value);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.controller});

  final SubscriptionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isOwner.value && !controller.restricted.value) {
        return const _OwnerOnlyNotice();
      }

      final current = controller.current.value;
      final alerts = controller.alerts.value;
      final overview = controller.overview.value;
      final invoices = controller.invoices;
      final billingDay = current?.billingDay;
      final highlightInvoice = _highlightedPendingInvoice(
        invoices,
        billingDay,
      );

      return RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: 'Plano e cobran\u00e7a',
              subtitle: 'Informa\u00e7\u00f5es b\u00e1sicas e dia padr\u00e3o de cobran\u00e7a.',
              actionLabel: 'Alterar dia de cobran\u00e7a',
              onAction: () => _openBillingDayForm(context, controller),
            ),
            _CurrentPlanCard(
              current: current,
              alerts: alerts,
              onEdit: () => _openBillingDayForm(context, controller),
            ),
            const SizedBox(height: 16),
            _CarnetActions(controller: controller),
            const SizedBox(height: 16),
            if (highlightInvoice != null) ...[
              _PendingInvoiceCard(
                invoice: highlightInvoice,
                billingDay: billingDay,
                startedAt: current?.startedAt,
                planAmount: current?.plan?.amount,
              ),
              const SizedBox(height: 24),
            ],
            _SectionHeader(
              title: 'Indicadores financeiros',
              subtitle: 'MRR, ARR e status da pr\u00f3xima fatura.',
            ),
            _OverviewMetricsGrid(
              overview: overview,
              billingDay: billingDay,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Alertas e status',
              subtitle: 'Acompanhamento autom\u00e1tico da API.',
            ),
            _AlertsCard(alerts: alerts, current: current),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Hist\u00f3rico e documentos',
              subtitle:
                  'Use a aba de faturas para pagamentos e comprovantes detalhados.',
            ),
            const _PlaceholderCard(),
          ],
        ),
      );
    });
  }

  Future<void> _openBillingDayForm(
    BuildContext context,
    SubscriptionsController controller,
  ) async {
    final current = controller.current.value;
    final formKey = GlobalKey<FormState>();
    final billingDayCtrl =
        TextEditingController(text: current?.billingDay?.toString() ?? '');

    await showModalBottomSheet<void>(
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
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Alterar dia de cobrança',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informe um dia entre 1 e 28. As próximas faturas usarão este vencimento.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: billingDayCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Dia de cobrança (1-28)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe o dia';
                    final number = int.tryParse(value);
                    if (number == null || number < 1 || number > 28) {
                      return 'Digite um número entre 1 e 28';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final day = int.tryParse(billingDayCtrl.text.trim());
                      await controller.updateCurrentSettings(billingDay: day);
                      if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                    },
                    child: const Text(
                      'Salvar dia de cobrança',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    billingDayCtrl.dispose();
  }

  SubscriptionInvoiceModel? _highlightedPendingInvoice(
    List<SubscriptionInvoiceModel> invoices,
    int? billingDay,
  ) {
    final pending = invoices.where((inv) => inv.isPending).toList()
      ..sort((a, b) {
        final aDate = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
    if (pending.isEmpty) return null;
    if (billingDay != null) {
      final match = pending.firstWhere(
        (inv) => inv.dueDate != null && inv.dueDate!.day == billingDay,
        orElse: () => pending.first,
      );
      return match;
    }
    return pending.first;
  }
}

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({required this.controller});

  final SubscriptionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final invoices = controller.invoices;
      final billingDay = controller.current.value?.billingDay;
      final planAmount = controller.current.value?.plan?.amount;
      return RefreshIndicator(
        onRefresh: controller.loadInvoices,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InvoiceFiltersBar(controller: controller),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: invoices.isEmpty
                  ? const _EmptyInvoicesView()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final inv = invoices[index];
                        return _InvoiceTile(
                          invoice: inv,
                          billingDay: billingDay,
                          planAmount: planAmount,
                          controller: controller,
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.current,
    required this.alerts,
    required this.onEdit,
  });

  final SubscriptionCurrentModel? current;
  final SubscriptionAlertModel? alerts;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final planStatus = current?.status ?? alerts?.status ?? 'active';
    final contact = [
      if ((current?.billingContactName ?? '').isNotEmpty)
        current!.billingContactName!,
      if ((current?.billingContactEmail ?? '').isNotEmpty)
        current!.billingContactEmail!,
      if ((current?.billingContactPhone ?? '').isNotEmpty)
        current!.billingContactPhone!,
    ].join(' \u00b7 ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        (current?.plan?.name ?? '').isNotEmpty
                            ? current!.plan!.name
                            : 'Assinatura atual',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plano fixo AirSync para todo tenant. Sem necessidade de upgrades.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: planStatus),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _InfoTile(
                  icon: Icons.event_repeat_rounded,
                  label: 'Pr\u00f3xima cobran\u00e7a',
                  value: SubscriptionsPage.formatDate(
                    current?.renewsAt ?? alerts?.nextDueDate,
                  ),
                  helper: 'Data estimada para a renova\u00e7\u00e3o do plano.',
                ),
                _InfoTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Dia padr\u00e3o',
                  value: current?.billingDay?.toString() ?? '--',
                  helper: 'Dia do m\u00eas em que o boleto/cart\u00e3o \u00e9 cobrado.',
                ),
                _InfoTile(
                  icon: Icons.account_circle_outlined,
                  label: 'Contato financeiro',
                  value: contact.isEmpty ? '--' : contact,
                  helper: 'Pessoa avisada sobre cobran\u00e7as e notas fiscais.',
                ),
              ],
            ),
            if ((current?.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                current!.notes!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Alterar dia de cobran\u00e7a',
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _OverviewMetricsGrid extends StatelessWidget {
  const _OverviewMetricsGrid({this.overview, this.billingDay});

  final SubscriptionOverviewModel? overview;
  final int? billingDay;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricData(
        label: 'Receita mensal estimada',
        value: overview == null
            ? '--'
            : SubscriptionsPage.formatCurrency(
                overview!.mrr,
                currency: overview!.currency,
              ),
        icon: Icons.show_chart_rounded,
        helper: 'Valor recorrente do plano a cada mês.',
      ),
      _MetricData(
        label: 'Receita anual estimada',
        value: overview == null
            ? '--'
            : SubscriptionsPage.formatCurrency(
                overview!.arr,
                currency: overview!.currency,
              ),
        icon: Icons.trending_up_outlined,
        helper: 'Equivalente a 12 meses de assinatura.',
      ),
      _MetricData(
        label: 'Receita dos últimos 30 dias',
        value: overview == null
            ? '--'
            : SubscriptionsPage.formatCurrency(
                overview!.last30Revenue,
                currency: overview!.currency,
              ),
        icon: Icons.calendar_view_month,
        helper: 'Tudo que foi pago no último mês.',
      ),
      _MetricData(
        label: 'Total pendente',
        value: overview == null
            ? '--'
            : SubscriptionsPage.formatCurrency(
                overview!.outstandingAmount,
                currency: overview!.currency,
              ),
        icon: Icons.warning_amber_rounded,
        helper: 'Inclui pró-rata inicial e faturas abertas.',
      ),
      _MetricData(
        label: 'Próxima fatura programada',
        value: overview?.nextInvoice == null
            ? '--'
            : '${SubscriptionsPage.formatCurrency(overview!.nextInvoice!.amountDue, currency: overview!.nextInvoice!.currency)} - ${SubscriptionsPage.formatDate(overview!.nextInvoice!.dueDate)}',
        icon: Icons.receipt_long_outlined,
        helper: billingDay == null
            ? 'Valor e data previstos para o próximo ciclo.'
            : 'Vencimento fixo todo dia ${billingDay!}.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth > 640;
        final tileWidth =
            twoColumns ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: tileWidth,
                  child: _InfoTile(
                    icon: tile.icon,
                    label: tile.label,
                    value: tile.value,
                    helper: tile.helper,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}


class _PendingInvoiceCard extends StatelessWidget {
  const _PendingInvoiceCard({
    required this.invoice,
    required this.billingDay,
    required this.startedAt,
    this.planAmount,
  });

  final SubscriptionInvoiceModel invoice;
  final int? billingDay;
  final DateTime? startedAt;
  final double? planAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProrated = _isProratedInvoice(invoice, planAmount: planAmount);
    final isTrial = _isTrialInvoice(invoice);
    final dueDateLabel = SubscriptionsPage.formatDate(invoice.dueDate);
    final startLabel =
        startedAt != null ? SubscriptionsPage.formatDate(startedAt) : 'a ativa\u00e7\u00e3o';
    final billingLabel =
        billingDay != null ? 'dia $billingDay' : 'o vencimento informado';
    final subtitle = isTrial
        ? 'Car\u00eancia ativa: use o sistema sem cobran\u00e7a e pague at\u00e9 $dueDateLabel.'
        : isProrated
            ? 'Valor proporcional entre $startLabel e o $billingLabel. Pagamento opcional at\u00e9 $dueDateLabel.'
            : 'Cobran\u00e7a fixa gerada todo $billingLabel.';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        isTrial
                            ? 'Trial ativo'
                            : isProrated
                                ? 'Pr\u00f3-rata pendente'
                                : 'Fatura pendente',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vence em $dueDateLabel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isTrial || isProrated)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.orange.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      isTrial
                          ? 'Em car\u00eancia'
                          : 'Pr\u00f3-rata aplicada',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  _StatusChip(status: invoice.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              SubscriptionsPage.formatCurrency(
                invoice.amountDue,
                currency: invoice.currency,
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  final tabController = DefaultTabController.of(context);
                  tabController.animateTo(1);
                  Get.find<SubscriptionsController>()
                      .setInvoiceFilter('pending');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver detalhes nas faturas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({this.alerts, this.current});

  final SubscriptionAlertModel? alerts;
  final SubscriptionCurrentModel? current;

  @override
  Widget build(BuildContext context) {
    if (alerts == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Nenhum alerta ativo. Continuamos monitorando seu faturamento.',
          ),
        ),
      );
    }

    final billingDay = current?.billingDay;
    final startedAt = current?.startedAt;
    final planPrice =
        current?.plan?.formattedPrice ??
        SubscriptionsPage.formatCurrency(_fixedPlanAmount);

    final rows = <Widget>[
      _InfoTile(
        icon: Icons.shield_outlined,
        label: 'Status',
        value: _resolveStatusLabel(alerts!.status),
        helper: _statusHelper(alerts!.status),
      ),
      _InfoTile(
        icon: Icons.timer_outlined,
        label: 'Dias at\u00e9 o vencimento',
        value: alerts!.daysUntilDue?.toString() ?? '--',
        helper: 'Mostra quanto tempo resta antes da suspens\u00e3o.',
      ),
      _InfoTile(
        icon: Icons.calendar_today_outlined,
        label: 'Pr\u00f3xima cobran\u00e7a',
        value: SubscriptionsPage.formatDate(alerts!.nextDueDate),
        helper: 'Data limite esperada para o pagamento atual.',
      ),
      _InfoTile(
        icon: Icons.hourglass_top_outlined,
        label: 'Trial at\u00e9',
        value: SubscriptionsPage.formatDate(alerts!.trialEndsAt),
        helper: 'Somente exibido se ainda estiver em testes.',
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((alerts!.message ?? '').isNotEmpty) ...[
              Text(
                alerts!.message!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: rows,
            ),
            if (alerts!.nextDueDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Voc\u00ea pode usar o sistema sem cobran\u00e7a at\u00e9 ${SubscriptionsPage.formatDate(alerts!.nextDueDate)}. Depois da car\u00eancia, o valor do plano \u00e9 $planPrice.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
            if (billingDay != null) ...[
              const SizedBox(height: 16),
              Text(
                'Contagem iniciada em ${SubscriptionsPage.formatDate(startedAt)} '
                'com vencimento recorrente no dia $billingDay.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
            if (alerts!.suspensionOverrideUntil != null) ...[
              const SizedBox(height: 16),
              Text(
                'Car\u00eancia ativa at\u00e9 ${SubscriptionsPage.formatDate(alerts!.suspensionOverrideUntil)}.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.orangeAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _resolveStatusLabel(String status) {
    switch (status) {
      case 'trial':
        return 'Per\u00edodo de testes';
      case 'past_due':
        return 'Vencido';
      case 'suspended':
        return 'Suspenso';
      case 'active':
        return 'Ativo';
      default:
        return status;
    }
  }

  static String _statusHelper(String status) {
    switch (status) {
      case 'trial':
        return 'Conta ainda em experi\u00eancia gratuita.';
      case 'past_due':
        return 'Existe pagamento atrasado aguardando regulariza\u00e7\u00e3o.';
      case 'suspended':
        return 'Acesso pode ser bloqueado at\u00e9 o pagamento.';
      case 'active':
        return 'Tudo certo: cobran\u00e7as em dia.';
      default:
        return 'Situa\u00e7\u00e3o fornecida pelo financeiro.';
    }
  }
}
class _InvoiceFiltersBar extends StatelessWidget {
  const _InvoiceFiltersBar({required this.controller});

  final SubscriptionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final from = controller.invoiceFrom.value;
      final to = controller.invoiceTo.value;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: controller.invoiceStatusFilter.value == 'all',
                  onSelected: () => controller.setInvoiceFilter('all'),
                ),
                _FilterChip(
                  label: 'Pendentes',
                  selected: controller.invoiceStatusFilter.value == 'pending',
                  onSelected: () => controller.setInvoiceFilter('pending'),
                ),
                _FilterChip(
                  label: 'Pagas',
                  selected: controller.invoiceStatusFilter.value == 'paid',
                  onSelected: () => controller.setInvoiceFilter('paid'),
                ),
                _FilterChip(
                  label: 'Em atraso',
                  selected: controller.invoiceStatusFilter.value == 'past_due',
                  onSelected: () => controller.setInvoiceFilter('past_due'),
                ),
                _FilterChip(
                  label: 'Abertas',
                  selected: controller.invoiceStatusFilter.value == 'open',
                  onSelected: () => controller.setInvoiceFilter('open'),
                ),
                _FilterChip(
                  label: 'Canceladas',
                  selected: controller.invoiceStatusFilter.value == 'canceled',
                  onSelected: () => controller.setInvoiceFilter('canceled'),
                ),
                _FilterChip(
                  label: 'Anuladas',
                  selected: controller.invoiceStatusFilter.value == 'void',
                  onSelected: () => controller.setInvoiceFilter('void'),
                ),
                _FilterChip(
                  label: 'Inadimplentes',
                  selected:
                      controller.invoiceStatusFilter.value == 'uncollectible',
                  onSelected: () => controller.setInvoiceFilter('uncollectible'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text(
                    from == null
                        ? 'Data inicial'
                        : SubscriptionsPage.formatDate(from),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: from ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      controller.setInvoiceRange(from: picked, to: to);
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(
                    to == null
                        ? 'Data final'
                        : SubscriptionsPage.formatDate(to),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: to ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      controller.setInvoiceRange(from: from, to: picked);
                    }
                  },
                ),
                if (from != null || to != null)
                  TextButton(
                    onPressed: controller.clearInvoiceRange,
                    child: const Text('Limpar per\u00edodo'),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({
    required this.invoice,
    required this.controller,
    this.billingDay,
    this.planAmount,
  });

  final SubscriptionInvoiceModel invoice;
  final SubscriptionsController controller;
  final int? billingDay;
  final double? planAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProrated = _isProratedInvoice(invoice, planAmount: planAmount);
    final isTrial = _isTrialInvoice(invoice);
    final double openAmount = invoice.amountDue;
    final helperText = () {
      if (isTrial) {
        final due = SubscriptionsPage.formatDate(invoice.dueDate);
        return 'Car\u00eancia ativa: pagamento at\u00e9 $due.';
      }
      if (isProrated) {
        return 'Pr\u00f3-rata inicial antes do ciclo cheio.';
      }
      if (billingDay != null) {
        return 'Ciclo mensal fixo no dia $billingDay.';
      }
      return null;
    }();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.reference ?? 'Fatura ${invoice.id}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vencimento ${SubscriptionsPage.formatDate(invoice.dueDate)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (isTrial || isProrated) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isTrial
                              ? 'Em car\u00eancia'
                              : 'Pr\u00f3-rata',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (helperText != null && !(isTrial || isProrated)) ...[
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      SubscriptionsPage.formatCurrency(
                        invoice.amountDue,
                        currency: invoice.currency,
                      ),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _StatusChip(status: invoice.status),
                    ),
                    if (invoice.isPending) ...[
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 40),
                        ),
                        onPressed: () => _showPaySheet(context, openAmount),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('Pagar agora'),
                      ),
                    ],
                    if (helperText != null && (isTrial || isProrated)) ...[
                      const SizedBox(height: 4),
                      Text(
                        helperText,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaySheet(BuildContext context, double openAmount) {
    String method = 'PIX';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (_, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pagar fatura',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Valor a pagar (fixo): ${SubscriptionsPage.formatCurrency(openAmount, currency: invoice.currency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                items: const [
                  DropdownMenuItem(value: 'PIX', child: Text('PIX')),
                  DropdownMenuItem(value: 'CARD_CREDIT', child: Text('Cart\u00e3o de cr\u00e9dito')),
                  DropdownMenuItem(value: 'CARD_DEBIT', child: Text('Cart\u00e3o de d\u00e9bito')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Transfer\u00eancia banc\u00e1ria')),
                ],
                onChanged: (v) => setState(() => method = v ?? 'PIX'),
                decoration: const InputDecoration(labelText: 'M\u00e9todo de pagamento'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Gerar pagamento'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final intent = await controller.createPaymentIntent(
                      invoiceId: invoice.id,
                      method: method,
                    );
                    if (!context.mounted) return;
                    if (intent != null) {
                      await _handleStripePayment(context, intent);
                      if (!context.mounted) return;
                      await _showStripeInfo(context, intent, method);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _showStripeInfo(
    BuildContext context,
    SubscriptionPaymentIntentResult intent,
    String method,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento Stripe ($method)',
              style: Theme.of(ctx)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if ((intent.pixCopyAndPaste ?? '').isNotEmpty) ...[
              const Text(
                'PIX Copia e Cola',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SelectableText(intent.pixCopyAndPaste!),
            ] else if (intent.clientSecret.isNotEmpty) ...[
              const Text(
                'Pagamento iniciado. Finalize no provedor ou com o client secret abaixo:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SelectableText(intent.clientSecret),
            ] else
              const Text('Pagamento iniciado. Siga as instru\u00e7\u00f5es do provedor.'),
            if (intent.expiresAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Expira em: ${SubscriptionsPage.formatDate(intent.expiresAt)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStripePayment(
    BuildContext context,
    SubscriptionPaymentIntentResult intent,
  ) async {
    if (intent.clientSecret.isEmpty) return;
    try {
      final configKey = Get.find<AppConfig>().stripePublishableKey;
      final publishableKey = (intent.publishableKey ?? '').isNotEmpty
          ? intent.publishableKey!
          : configKey;
      if (publishableKey.isEmpty) {
        Get.snackbar(
          'Pagamento',
          'Chave do Stripe não configurada.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        );
        return;
      }
      stripe.Stripe.publishableKey = publishableKey;
      stripe.Stripe.merchantIdentifier = 'merchant.com.airsync';
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'AirSync',
          style: ThemeMode.dark,
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      Get.snackbar(
        'Pagamento',
        'Pagamento processado com sucesso.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await controller.loadInvoices();
    } on stripe.StripeException catch (e) {
      Get.snackbar(
        'Pagamento',
        'Stripe: ${e.error.localizedMessage ?? e.error.message ?? 'Falha no pagamento.'}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      );
    } catch (e) {
      Get.snackbar(
        'Pagamento',
        'Falha ao abrir o fluxo do Stripe: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precisa localizar recibos ou notas?',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Abra a aba de faturas para baixar PDFs, registrar pagamentos manuais e acompanhar o status enviado pela Stripe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarnetActions extends StatelessWidget {
  const _CarnetActions({required this.controller});

  final SubscriptionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
              const Icon(Icons.receipt_long_outlined, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Carnê semestral',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (controller.isCreatingCarnet.value)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'As faturas do carnê de 6 meses já aparecem automaticamente. Use aqui se quiser forçar nova geração (6x) ou uma fatura única com 20% de desconto à vista.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 180,
                    child: _ActionButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'Carnê 6x',
                      isLoading: controller.isCreatingCarnet.value,
                      onPressed: () => controller.createCarnet(payUpfront: false),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: _ActionButton(
                      icon: Icons.percent_rounded,
                      label: 'À vista (20% off)',
                      isLoading: controller.isCreatingCarnet.value,
                      onPressed: () => controller.createCarnet(payUpfront: true),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        minimumSize: const Size(0, 48),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      label: Text(_label(status)),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'active':
        return Colors.greenAccent;
      case 'pending':
      case 'open':
        return Colors.amberAccent;
      case 'past_due':
      case 'suspended':
        return Colors.redAccent;
      case 'canceled':
      case 'void':
      case 'uncollectible':
        return Colors.white70;
      default:
        return Colors.blueAccent;
    }
  }

  static String _label(String status) {
    switch (status) {
      case 'paid':
        return 'Paga';
      case 'pending':
        return 'Pendente';
      case 'open':
        return 'Aberta';
      case 'past_due':
        return 'Em atraso';
      case 'suspended':
        return 'Suspensa';
      case 'trial':
        return 'Em teste';
      case 'active':
        return 'Ativa';
      case 'canceled':
        return 'Cancelada';
      case 'void':
        return 'Anulada';
      case 'uncollectible':
        return 'Inadimplente';
      default:
        return status;
    }
  }
}

class _OwnerOnlyNotice extends StatelessWidget {
  const _OwnerOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Apenas Administradores Globais podem acessar o faturamento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInvoicesView extends StatelessWidget {
  const _EmptyInvoicesView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      children: [
        Icon(Icons.receipt_long_outlined,
            size: 56, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(height: 16),
        const Text(
          'Nenhuma fatura para o filtro selecionado.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Altere o per\u00edodo ou gere um novo pagamento pela Stripe.',
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _MetricData {
  _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helper;
}
