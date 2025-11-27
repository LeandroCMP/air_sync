import 'dart:convert';

import 'package:air_sync/application/core/network/app_config.dart';
import 'package:air_sync/application/ui/input_formatters.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/models/subscription_models.dart';
import 'package:air_sync/modules/subscriptions/subscriptions_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:intl/intl.dart';

const String _fixedPlanName = 'AirSync Standard - R\$ 120/m\u00eas';
const double _fixedPlanAmount = 120;
const int _graceDays = 3;
const String _stripeMerchantIdentifier = 'merchant.com.airsync';

bool _isProratedInvoice(SubscriptionInvoiceModel invoice) =>
    invoice.amountDue < (_fixedPlanAmount - 0.01) &&
    invoice.amountDue > 0;

bool _isTrialInvoice(SubscriptionInvoiceModel invoice) =>
    invoice.amountDue <= 0.01;

class SubscriptionsPage extends GetView<SubscriptionsController> {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minha assinatura'),
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
      if (!controller.isOwner.value) {
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
              subtitle:
                  'Informa\u00e7\u00f5es fixas do plano AirSync e contatos financeiros.',
              actionLabel: 'Editar prefer\u00eancias',
              onAction: () => _openBillingPreferencesForm(context, controller),
            ),
            _CurrentPlanCard(
              current: current,
              alerts: alerts,
              onEdit: () => _openBillingPreferencesForm(context, controller),
              onRunCycle: controller.runBillingNow,
              isRunningBilling: controller.isRunningBilling.value,
            ),
            const SizedBox(height: 16),
            if (highlightInvoice != null) ...[
              _PendingInvoiceCard(
                invoice: highlightInvoice,
                billingDay: billingDay,
                startedAt: current?.startedAt,
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

  Future<void> _openBillingPreferencesForm(
    BuildContext context,
    SubscriptionsController controller,
  ) async {
    final current = controller.current.value;
    final formKey = GlobalKey<FormState>();
    final nameCtrl =
        TextEditingController(text: current?.billingContactName ?? '');
    final emailCtrl =
        TextEditingController(text: current?.billingContactEmail ?? '');
    final phoneCtrl =
        TextEditingController(text: current?.billingContactPhone ?? '');
    final methodCtrl =
        TextEditingController(text: current?.preferredPaymentMethod ?? '');
    final notesCtrl = TextEditingController(text: current?.notes ?? '');
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
                  'Prefer\u00eancias de pagamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Atualize o contato financeiro, dia de cobran\u00e7a e observac\u00f5es que aparecer\u00e3o nas faturas.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: billingDayCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Dia de cobran\u00e7a (1-28)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final number = int.tryParse(value);
                    if (number == null || number < 1 || number > 28) {
                      return 'Informe um dia entre 1 e 28';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Respons\u00e1vel financeiro',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'E-mail para cobran\u00e7as',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final regex = RegExp(r'^\S+@\S+\.\S+$');
                    if (!regex.hasMatch(value.trim())) {
                      return 'Digite um e-mail v\u00e1lido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Telefone para contato',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: methodCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'M\u00e9todo preferido (PIX, cart\u00e3o...)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Observa\u00e7\u00f5es para o financeiro',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final trimmed = billingDayCtrl.text.trim();
                      final billingDay =
                          trimmed.isEmpty ? null : int.tryParse(trimmed);
                      await controller.updateCurrentSettings(
                        billingDay: billingDay,
                        billingContactName: nameCtrl.text.trim().isEmpty
                            ? null
                            : nameCtrl.text.trim(),
                        billingContactEmail: emailCtrl.text.trim().isEmpty
                            ? null
                            : emailCtrl.text.trim(),
                        billingContactPhone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                        preferredPaymentMethod: methodCtrl.text.trim().isEmpty
                            ? null
                            : methodCtrl.text.trim(),
                        notes:
                            notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                      );
                      if (sheetCtx.mounted) {
                        Navigator.of(sheetCtx).pop();
                      }
                    },
                    child: const Text(
                      'Salvar prefer\u00eancias',
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

    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    methodCtrl.dispose();
    notesCtrl.dispose();
    billingDayCtrl.dispose();
  }
}

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({required this.controller});

  final SubscriptionsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isOwner.value) {
        return const _OwnerOnlyNotice();
      }

      final invoices = controller.invoices;

      return Column(
        children: [
          _InvoiceFiltersBar(controller: controller),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.loadInvoices,
              child: invoices.isEmpty
                  ? const _EmptyInvoicesView()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemBuilder: (_, index) {
                        final invoice = invoices[index];
                        return _InvoiceTile(
                          invoice: invoice,
                          billingDay: controller.current.value?.billingDay,
                          onTap: () => _openInvoiceDetail(context, invoice),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: invoices.length,
                    ),
            ),
          ),
        ],
      );
    });
  }

  void _openInvoiceDetail(
    BuildContext context,
    SubscriptionInvoiceModel invoice,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Obx(() {
          final intent = controller.lastIntentByInvoice[invoice.id];
          final invoiceToUse = _findInvoice(invoice.id) ?? invoice;
          final billingDay = controller.current.value?.billingDay;
          final startedAt = controller.current.value?.startedAt;
          final isTrialAmount = _isTrialInvoice(invoiceToUse);
          final isProratedAmount = _isProratedInvoice(invoiceToUse);
          final startLabel = startedAt != null
              ? SubscriptionsPage.formatDate(startedAt)
              : 'a ativa\u00e7\u00e3o';
          final billingLabel =
              billingDay ?? invoiceToUse.dueDate?.day ?? '--';

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fatura ${invoiceToUse.reference ?? invoiceToUse.id}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StatusChip(status: invoiceToUse.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    SubscriptionsPage.formatCurrency(
                      invoiceToUse.amountDue,
                      currency: invoiceToUse.currency,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vencimento: ${SubscriptionsPage.formatDate(invoiceToUse.dueDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Emitida em',
                        value:
                            SubscriptionsPage.formatDate(invoiceToUse.createdAt),
                      ),
                      _InfoTile(
                        icon: Icons.credit_card_outlined,
                        label: 'M\u00e9todo anterior',
                        value: invoiceToUse.paymentMethod ?? '--',
                      ),
                      _InfoTile(
                        icon: Icons.link_outlined,
                        label: 'Stripe ID',
                        value: invoiceToUse.stripeInvoiceId ?? '--',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isTrialAmount) ...[
                    _InfoBanner(
                      icon: Icons.auto_awesome_rounded,
                      text:
                          'Trial ativo - nenhuma cobran\u00e7a hoje. Voc\u00ea tem $_graceDays dias de car\u00eancia e pode pagar at\u00e9 ${SubscriptionsPage.formatDate(invoiceToUse.dueDate)} sem juros.',
                    ),
                    const SizedBox(height: 16),
                  ] else if (isProratedAmount) ...[
                    _InfoBanner(
                      icon: Icons.av_timer_rounded,
                      text:
                          'Cobran\u00e7a pr\u00f3-rata referente ao per\u00edodo entre $startLabel e o dia $billingLabel. Durante a car\u00eancia de $_graceDays dias, o pagamento \u00e9 opcional.',
                    ),
                    const SizedBox(height: 16),
                  ] else if (billingDay != null) ...[
                    _InfoBanner(
                      icon: Icons.calendar_month_outlined,
                      text:
                          'Esta fatura segue o ciclo fixo do dia $billingDay de cada m\u00eas.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (intent != null) _PaymentIntentResultView(intent: intent),
                  if (intent == null) ...[
                    if (isTrialAmount) ...[
                      _InfoBanner(
                        icon: Icons.celebration_rounded,
                        text:
                            'Trial ativo - nenhuma cobran\u00e7a hoje. Aproveite o sistema e volte quando quiser pagar.',
                      ),
                    ] else ...[
                      Text(
                        isProratedAmount
                            ? 'Pagamento opcional durante os $_graceDays dias iniciais:'
                            : 'Selecione a forma de pagamento:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ActionButton(
                            icon: Icons.pix,
                            label: 'Gerar PIX (Stripe)',
                            onPressed: () => _openPaymentMethodSheet(
                              context,
                              invoiceToUse,
                              'PIX',
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.credit_score_rounded,
                            label: 'Cart\u00e3o (Stripe)',
                            onPressed: () => _openPaymentMethodSheet(
                              context,
                              invoiceToUse,
                              'CARD_CREDIT',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Op\u00e7\u00f5es administrativas',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ActionButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Registrar pagamento',
                        onPressed: () =>
                            _openManualPaymentDialog(context, invoiceToUse),
                      ),
                      _ActionButton(
                        icon: Icons.support_agent_outlined,
                        label: 'Renegociar',
                        onPressed: () =>
                            _openNegotiateDialog(context, invoiceToUse),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ap\u00f3s confirmar algum pagamento aguarde alguns segundos e atualize a lista para ver o status atualizado.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _openPaymentMethodSheet(
    BuildContext context,
    SubscriptionInvoiceModel invoice,
    String method,
  ) async {
    if (method == 'CARD_CREDIT' && !_isStripeCardSupported()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pagamentos por cartão só estão disponíveis em Android, iOS ou Web.',
          ),
        ),
      );
      return;
    }
    final appConfig = Get.find<AppConfig>();
    if (method != 'PIX') {
      controller.lastIntentByInvoice.remove(invoice.id);
      controller.lastIntentByInvoice.refresh();
    }
    final publishableKey =
        method == 'PIX' ? null : appConfig.stripePublishableKey;
    if (method == 'CARD_CREDIT' &&
        (publishableKey == null || publishableKey.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configure a Stripe Publishable Key para aceitar pagamentos por cartão.',
          ),
        ),
      );
      return;
    }
    final intent = await controller.createPaymentIntent(
      invoiceId: invoice.id,
      method: method,
      cacheResult: method == 'PIX',
    );
    if (intent == null || !context.mounted) return;
    if (method == 'PIX') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('PIX gerado. Use o QR Code exibido para concluir o pagamento.'),
        ),
      );
      return;
    }
    try {
      if (publishableKey != null &&
          stripe.Stripe.publishableKey != publishableKey) {
        stripe.Stripe.publishableKey = publishableKey;
        stripe.Stripe.merchantIdentifier = _stripeMerchantIdentifier;
        await stripe.Stripe.instance.applySettings();
      }
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'AirSync',
          style: context.mounted && Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      if (context.mounted) {
        Navigator.of(context).pop(); // fecha o detalhe da fatura
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento processado pela Stripe.')),
        );
      }
      await controller.loadInvoices();
    } on stripe.StripeException catch (error) {
      final message = error.error.localizedMessage ?? 'Pagamento cancelado.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      Get.log('stripe_payment_error: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o pagamento Stripe.'),
          ),
        );
      }
    }
  }

  void _openManualPaymentDialog(
    BuildContext context,
    SubscriptionInvoiceModel invoice,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? paidAt = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Pagamento manual'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Use quando receber transfer\u00eancia ou PIX fora do Stripe.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Valor recebido (opcional)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Observa\u00e7\u00e3o'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Descreva como o pagamento foi confirmado';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pago em: ${SubscriptionsPage.formatDate(paidAt)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: paidAt ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => paidAt = picked);
                          }
                        },
                        child: const Text('Alterar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                await controller.registerManualPayment(
                  invoiceId: invoice.id,
                  note: noteCtrl.text.trim(),
                  paidAt: paidAt,
                  amount: amount,
                );
                Get.back();
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      }),
    );
  }

  void _openNegotiateDialog(
    BuildContext context,
    SubscriptionInvoiceModel invoice,
  ) {
    final formKey = GlobalKey<FormState>();
    final noteCtrl = TextEditingController();
    DateTime? newDate = invoice.dueDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Renegociar fatura'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: noteCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Mensagem ao financeiro'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Explique o motivo da renegocia\u00e7\u00e3o';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Novo vencimento: ${SubscriptionsPage.formatDate(newDate)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: newDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => newDate = picked);
                          }
                        },
                        child: const Text('Escolher data'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await controller.negotiateInvoice(
                  invoiceId: invoice.id,
                  note: noteCtrl.text.trim(),
                  newDueDate: newDate,
                );
                Get.back();
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      }),
    );
  }

  SubscriptionInvoiceModel? _findInvoice(String id) {
    for (final item in controller.invoices) {
      if (item.id == id) return item;
    }
    return null;
  }
}
class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.current,
    required this.alerts,
    required this.onEdit,
    required this.onRunCycle,
    required this.isRunningBilling,
  });

  final SubscriptionCurrentModel? current;
  final SubscriptionAlertModel? alerts;
  final VoidCallback onEdit;
  final VoidCallback onRunCycle;
  final bool isRunningBilling;

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
                        _fixedPlanName,
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
                  icon: Icons.payment_outlined,
                  label: 'M\u00e9todo preferido',
                  value: current?.preferredPaymentMethod ?? '--',
                  helper: 'Indica como voc\u00ea prefere pagar esta assinatura.',
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
                  label: 'Editar prefer\u00eancias',
                  onPressed: onEdit,
                ),
                _ActionButton(
                  icon: Icons.restart_alt_rounded,
                  label: isRunningBilling
                      ? 'Executando cobran\u00e7a...'
                      : 'Executar cobran\u00e7a agora',
                  onPressed: onRunCycle,
                  isLoading: isRunningBilling,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use este comando apenas quando precisar recalcular faturas e alertas imediatamente.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
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
        icon: Icons.timeline_outlined,
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
  });

  final SubscriptionInvoiceModel invoice;
  final int? billingDay;
  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProrated = _isProratedInvoice(invoice);
    final isTrial = _isTrialInvoice(invoice);
    final dueDateLabel = SubscriptionsPage.formatDate(invoice.dueDate);
    final startLabel =
        startedAt != null ? SubscriptionsPage.formatDate(startedAt) : 'a ativa\u00e7\u00e3o';
    final billingLabel =
        billingDay != null ? 'dia $billingDay' : 'o vencimento informado';
    final subtitle = isTrial
        ? 'Car\u00eancia de $_graceDays dias ativa: use o sistema sem cobran\u00e7a e pague at\u00e9 $dueDateLabel.'
        : isProrated
            ? 'Valor proporcional entre $startLabel e o $billingLabel. Durante a car\u00eancia o pagamento \u00e9 opcional.'
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
                          ? 'Car\u00eancia de $_graceDays dias'
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
                'Voc\u00ea pode usar o sistema sem cobran\u00e7a at\u00e9 ${SubscriptionsPage.formatDate(alerts!.nextDueDate)}. Depois da car\u00eancia, o valor fixo do plano \u00e9 ${SubscriptionsPage.formatCurrency(_fixedPlanAmount)}.',
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
  const _InvoiceTile({required this.invoice, this.onTap, this.billingDay});

  final SubscriptionInvoiceModel invoice;
  final VoidCallback? onTap;
  final int? billingDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProrated = _isProratedInvoice(invoice);
    final isTrial = _isTrialInvoice(invoice);
    final helperText = () {
      if (isTrial) {
        return 'Car\u00eancia de $_graceDays dias aplicada.';
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
        onTap: onTap,
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
                              ? 'Car\u00eancia de $_graceDays dias'
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
}

class _PaymentIntentResultView extends StatelessWidget {
  const _PaymentIntentResultView({required this.intent});

  final SubscriptionPaymentIntentResult intent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagamento iniciado (${intent.method}).',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.greenAccent),
            ),
            const SizedBox(height: 8),
            if (intent.pixQrCodeBase64 != null)
              Center(
                child: Image.memory(
                  base64Decode(intent.pixQrCodeBase64!),
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            if (intent.pixCopyAndPaste != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                intent.pixCopyAndPaste!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(text: intent.pixCopyAndPaste!),
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('C\u00f3digo PIX copiado.')),
                  );
                },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              intent.expiresAt == null
                  ? 'Aguarde confirma\u00e7\u00e3o da Stripe.'
                  : 'Expira em ${SubscriptionsPage.formatDate(intent.expiresAt)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ),
        ],
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
        return Colors.amberAccent;
      case 'past_due':
      case 'suspended':
        return Colors.redAccent;
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
      case 'past_due':
        return 'Em atraso';
      case 'suspended':
        return 'Suspensa';
      case 'trial':
        return 'Em teste';
      case 'active':
        return 'Ativa';
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

bool _isStripeCardSupported() {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}
