import 'package:air_sync/application/ui/theme_extensions.dart';

import 'package:air_sync/models/cost_center_model.dart';

import 'package:air_sync/models/finance_audit_model.dart';

import 'package:air_sync/models/finance_anomaly_model.dart';

import 'package:air_sync/models/finance_dashboard_model.dart';

import 'package:air_sync/models/finance_forecast_model.dart';

import 'package:air_sync/models/order_model.dart';

import 'package:air_sync/modules/finance/finance_reconciliation_page.dart';

import 'package:air_sync/modules/finance/widgets/aging_summary_card.dart';

import 'package:air_sync/modules/finance/widgets/payment_method_chart.dart';

import 'package:air_sync/modules/finance/widgets/purchases_summary_card.dart';

import 'package:air_sync/modules/finance/widgets/summary_grid.dart';

import 'package:air_sync/modules/orders/order_detail_bindings.dart';

import 'package:air_sync/modules/orders/order_detail_page.dart';

import 'package:air_sync/services/finance/finance_service.dart';

import 'package:air_sync/services/cost_centers/cost_centers_service.dart';

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:get/get.dart';

import 'package:intl/intl.dart';



final NumberFormat _currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');

final NumberFormat _intFormatter = NumberFormat.decimalPattern('pt_BR');



String _currency(double value) => _currencyFormatter.format(value);

String _int(num value) => _intFormatter.format(value);

String _percent(double value) {

  final normalized = value > 1 ? value : value * 100;

  return '${normalized.toStringAsFixed(1)}%';

}



class FinanceController extends GetxController {

  FinanceController({FinanceService? service}) : _service = service ?? Get.find<FinanceService>();



  final FinanceService _service;

  final RxBool loading = false.obs;

  final RxString errorMessage = ''.obs;

  final Rxn<FinanceDashboardModel> dashboard = Rxn<FinanceDashboardModel>();

  final Rx<DateTime> selectedMonth =

      DateTime(DateTime.now().year, DateTime.now().month, 1).obs;

  final DateFormat _monthParamFormatter = DateFormat('yyyy-MM');

  DateTime get _minSelectableMonth =>

      DateTime(DateTime.now().year - 2, 1, 1);

  DateTime get _maxSelectableMonth =>

      DateTime(DateTime.now().year + 1, 12, 1);

  final Rxn<FinanceAuditModel> audit = Rxn<FinanceAuditModel>();

  final RxBool auditLoading = false.obs;

  final RxString auditFilter = 'all'.obs;

  final Rxn<FinanceForecastModel> forecast = Rxn<FinanceForecastModel>();

  final RxBool forecastLoading = false.obs;

  final RxInt forecastDays = 30.obs;

  final RxList<CostCenterModel> costCenters = <CostCenterModel>[].obs;

  final RxnString selectedCostCenterId = RxnString();

  final RxBool costCentersLoading = false.obs;

  final RxBool allocationRunning = false.obs;

  final Rxn<FinanceAnomalyReport> anomalies = Rxn<FinanceAnomalyReport>();

  final RxBool anomaliesLoading = false.obs;

  final RxString anomaliesError = ''.obs;



  @override

  void onReady() {

    super.onReady();

    _loadCostCenters();

    load();

    loadAudit();

    loadForecast(days: forecastDays.value);

  }



  Future<void> load() async {

    loading.value = true;

    errorMessage.value = '';

    try {

      final monthParam = _monthParamFormatter.format(selectedMonth.value);

      final data = await _service.dashboard(

        month: monthParam,

        costCenterId: selectedCostCenterId.value,

      );

      dashboard.value = data;

    } catch (_) {

      errorMessage.value = 'Falha ao carregar dados do dashboard.';

    } finally {

      await loadAnomalies();

      loading.value = false;

    }

  }



  Future<void> pickMonth(BuildContext context) async {

    final current = selectedMonth.value;

    final pickerContext = _resolvePickerContext(context);

    final maxMonth = _maxSelectableMonth;

    final picked = await showDatePicker(

      context: pickerContext,

      initialDate: current,

      firstDate: _minSelectableMonth,

      lastDate: DateTime(

        maxMonth.year,

        maxMonth.month,

        DateUtils.getDaysInMonth(maxMonth.year, maxMonth.month),

      ),

      locale: const Locale('pt', 'BR'),

      helpText: 'Selecione o mês',

      cancelText: 'Cancelar',

      confirmText: 'Aplicar',

      builder: (ctx, child) {

        if (child == null) return const SizedBox.shrink();

        return Localizations.override(

          context: ctx,

          locale: const Locale('pt', 'BR'),

          delegates: const [

            GlobalMaterialLocalizations.delegate,

            GlobalWidgetsLocalizations.delegate,

            GlobalCupertinoLocalizations.delegate,

          ],

          child: child,

        );

      },

    );

    if (picked != null &&

        (picked.year != current.year || picked.month != current.month)) {

      selectedMonth.value = _normalizeMonth(picked);

      await load();

    }

  }



  Future<void> goToPreviousMonth() => _changeMonth(-1);



  Future<void> goToNextMonth() => _changeMonth(1);



  Future<void> goToCurrentMonth() async {

    final nowMonth = _normalizeMonth(DateTime.now());

    if (_isSameMonth(nowMonth, selectedMonth.value)) return;

    selectedMonth.value = nowMonth;

    await load();

  }



  bool get canGoToPreviousMonth =>

      _normalizeMonth(selectedMonth.value).isAfter(_minSelectableMonth);



  bool get canGoToNextMonth =>

      _normalizeMonth(selectedMonth.value).isBefore(_maxSelectableMonth);



  bool get isCurrentMonth =>

      _isSameMonth(selectedMonth.value, _normalizeMonth(DateTime.now()));



  Future<void> loadAudit() async {

    auditLoading.value = true;

    try {

      audit.value = await _service.audit(

        costCenterId: selectedCostCenterId.value,

      );

    } finally {

      auditLoading.value = false;

    }

  }



  Future<void> loadForecast({int? days}) async {

    final effectiveDays = days ?? forecastDays.value;

    forecastLoading.value = true;

    try {

      forecast.value = await _service.forecast(

        days: effectiveDays,

        costCenterId: selectedCostCenterId.value,

      );

    } finally {

      forecastLoading.value = false;

    }

  }



  Future<void> loadAnomalies() async {

    anomaliesLoading.value = true;

    anomaliesError.value = '';

    try {

      final monthParam = _monthParamFormatter.format(selectedMonth.value);

      anomalies.value = await _service.anomalies(

        month: monthParam,

        costCenterId: selectedCostCenterId.value,

      );

    } catch (_) {

      anomaliesError.value = 'No foi possvel gerar as anomalias financeiras.';

    } finally {

      anomaliesLoading.value = false;

    }

  }



  void setForecastDays(int days) {

    if (forecastDays.value == days) return;

    forecastDays.value = days;

    loadForecast(days: days);

  }



  void setAuditFilter(String value) {

    if (auditFilter.value == value) return;

    auditFilter.value = value;

  }



  Future<void> setCostCenter(String? id) async {

    final normalized = (id ?? '').trim();

    final value = normalized.isEmpty ? null : normalized;

    if (selectedCostCenterId.value == value) return;

    selectedCostCenterId.value = value;

    await refresh();

  }



  String get costCenterLabel {

    final id = selectedCostCenterId.value;

    if (id == null || id.isEmpty) return 'Todos os centros';

    for (final center in costCenters) {

      if (center.id == id) return center.name;

    }

    return 'Centro selecionado';

  }



  Future<void> allocateIndirectCosts({

    required DateTime from,

    required DateTime to,

    List<String> categories = const [],

  }) async {

    if (allocationRunning.value) return;

    allocationRunning.value = true;

    try {

      await _service.allocateIndirectCosts(

        from: from,

        to: to,

        categories: categories,

      );

      Get.snackbar(

        'Financeiro',

        'Rateio de indiretos solicitado com sucesso.',

        snackPosition: SnackPosition.BOTTOM,

      );

      await refresh();

    } catch (_) {

      Get.snackbar(

        'Financeiro',

        'Falha ao executar rateio de indiretos.',

        snackPosition: SnackPosition.BOTTOM,

      );

    } finally {

      allocationRunning.value = false;

    }

  }



  @override

  Future<void> refresh() async {

    await load();

    await Future.wait([

      loadAudit(),

      loadForecast(days: forecastDays.value),

    ]);

  }



  String get periodLabel {

    final data = dashboard.value;

    final fallback = DateFormat("MMMM 'de' yyyy", 'pt_BR');

    if (data == null) {

      return 'Período: ${fallback.format(selectedMonth.value)}';

    }

    final from = data.period.from;

    final to = data.period.to;

    if (from == null || to == null) {

      return 'Período: ${fallback.format(selectedMonth.value)}';

    }

    final fromFmt = DateFormat('dd/MM', 'pt_BR');

    final toFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

    return 'Período: ${fromFmt.format(from)} - ${toFmt.format(to)}';

  }



  String get monthChipLabel {

    final fmt = DateFormat("MMMM 'de' yyyy", 'pt_BR');

    return fmt.format(selectedMonth.value);

  }



  Future<void> _changeMonth(int offset) async {

    final current = selectedMonth.value;

    final candidate = DateTime(current.year, current.month + offset, 1);

    if (!_isWithinSelectableRange(candidate)) return;

    selectedMonth.value = _normalizeMonth(candidate);

    await load();

  }



  DateTime _normalizeMonth(DateTime date) => DateTime(date.year, date.month, 1);



  bool _isWithinSelectableRange(DateTime date) {

    final normalized = _normalizeMonth(date);

    return !normalized.isBefore(_minSelectableMonth) &&

        !normalized.isAfter(_maxSelectableMonth);

  }



  bool _isSameMonth(DateTime a, DateTime b) =>

      a.year == b.year && a.month == b.month;



  Future<void> _loadCostCenters() async {

    if (!Get.isRegistered<CostCentersService>()) return;

    costCentersLoading.value = true;

    try {

      final service = Get.find<CostCentersService>();

      final result = await service.list(includeInactive: false);

      final active = result.where((center) => center.active).toList()

        ..sort(

          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),

        );

      costCenters.assignAll(active);

      final selected = selectedCostCenterId.value;

      if (selected != null &&

          active.every((center) => center.id != selected)) {

        selectedCostCenterId.value = null;

      }

    } catch (_) {

      costCenters.clear();

    } finally {

      costCentersLoading.value = false;

    }

  }



  BuildContext _resolvePickerContext(BuildContext context) {

    if (_hasMaterialLocalizations(context)) {

      return context;

    }

    final navigatorState = Navigator.maybeOf(context, rootNavigator: true);

    if (navigatorState != null &&

        _hasMaterialLocalizations(navigatorState.context)) {

      return navigatorState.context;

    }

    if (Get.context != null &&

        _hasMaterialLocalizations(Get.context!)) {

      return Get.context!;

    }

    if (Get.overlayContext != null &&

        _hasMaterialLocalizations(Get.overlayContext!)) {

      return Get.overlayContext!;

    }

    return context;

  }



  bool _hasMaterialLocalizations(BuildContext context) =>

      Localizations.of<MaterialLocalizations>(

            context,

            MaterialLocalizations,

          ) !=

          null;

}



class FinancePage extends StatelessWidget {

  const FinancePage({super.key});



  @override

  Widget build(BuildContext context) {

    return GetX<FinanceController>(

      init: FinanceController(),

      builder: (controller) {

        final data = controller.dashboard.value;

        return Scaffold(

          backgroundColor: context.themeBg,

          appBar: AppBar(

            title: const Text('Financeiro'),

            elevation: 0,

            backgroundColor: context.themeSurfaceAlt,

            actions: [

              IconButton(

                tooltip: 'Centros de custo',

                icon: const Icon(Icons.account_tree_outlined),

                onPressed: () => Get.toNamed('/finance/cost-centers'),

              ),

              IconButton(

                tooltip: 'Atualizar',

                icon: const Icon(Icons.refresh_rounded),

                onPressed: controller.loading.value ? null : controller.refresh,

              ),

            ],

            bottom: controller.loading.value

                ? const PreferredSize(

                    preferredSize: Size.fromHeight(2),

                    child: LinearProgressIndicator(minHeight: 2),

                  )

                : null,

          ),

          body: _FinanceDashboardBody(controller: controller, data: data),

        );

      },

    );

  }

}



class _FinanceDashboardBody extends StatelessWidget {

  final FinanceController controller;

  final FinanceDashboardModel? data;



  const _FinanceDashboardBody({

    required this.controller,

    required this.data,

  });



  @override

  Widget build(BuildContext context) {

    return RefreshIndicator(

      color: context.themePrimary,

      onRefresh: controller.refresh,

          child: ListView(

        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),

        physics: const AlwaysScrollableScrollPhysics(),

        children: [

          _ShortcutRow(

            onAuditTap: () => Get.to(() => const FinanceAuditPage()),

            onForecastTap: () => Get.to(() => const FinanceForecastPage()),

            onAllocationTap: () => _openAllocationSheet(context),

            allocationLoading: controller.allocationRunning.value,

            onReconciliationTap: () => Get.to(

              () => const FinanceReconciliationPage(),

            ),

          ),

          const SizedBox(height: 12),

          _FilterRow(controller: controller),

          const SizedBox(height: 20),

          if (controller.loading.value && data == null)

            _PlaceholderCard(

              child: Column(

                children: const [

                  CircularProgressIndicator(),

                  SizedBox(height: 12),

                  Text('Carregando dados do Período...'),

                ],

              ),

            )

          else if (controller.errorMessage.value.isNotEmpty && data == null)

            _PlaceholderCard(

              child: Column(

                children: [

                  const Icon(Icons.warning_amber_rounded, size: 36),

                  const SizedBox(height: 8),

                  Text(

                    controller.errorMessage.value,

                    textAlign: TextAlign.center,

                  ),

                  TextButton(

                    onPressed: controller.load,

                    child: const Text('Tentar novamente'),

                  ),

                ],

              ),

            )

          else if (data == null)

            _PlaceholderCard(

              child: Text(

                'Sem dados disponíveis para o Período selecionado.',

                style: TextStyle(color: context.themeTextSubtle),

                textAlign: TextAlign.center,

              ),

            )

          else ...[

            ..._dashboardSections(

              context,

              data!,

              (status) => Get.toNamed(

                '/purchases',

                arguments: {'statusFilter': status},

              ),

            ),

            const SizedBox(height: 20),

            _FinanceAnomaliesSection(controller: controller),

            const SizedBox(height: 20),

            _AuditSection(controller: controller),

            const SizedBox(height: 20),

            _ForecastSection(

              forecast: controller.forecast.value,

              isLoading: controller.forecastLoading.value,

              selectedDays: controller.forecastDays.value,

              onDaysChanged: controller.setForecastDays,

              onRefresh: controller.loadForecast,

            ),

          ],

        ],

      ),

    );

  }

  List<SummaryGridItem> _summaryItems(

    BuildContext context,

    FinanceDashboardModel dashboard,

  ) {

    final cards = dashboard.cards;

    final bruto = cards.grossCollected != 0 ? cards.grossCollected : cards.revenue;

    final liquido = cards.netCollected;

    final custosMateriais = cards.materialCost;

    final custosCompras = cards.purchaseCost;

    final custosTotal = custosMateriais + custosCompras;

    final lucroLiquido = liquido - custosTotal;



    return [

      SummaryGridItem(

        label: 'OSs finalizadas',

        value: _int(cards.ordersDone),

        helper: cards.month.isNotEmpty ? cards.month : null,

        icon: Icons.assignment_turned_in_rounded,

        color: context.themeInfo,

      ),

      SummaryGridItem(

        label: 'Receita (bruta)',

        value: _currency(bruto),

        helper: 'Líquido ${_currency(liquido)}',

        icon: Icons.payments_rounded,

        color: context.themePrimary,

      ),

      SummaryGridItem(

        label: 'Ticket mdio',

        value: _currency(cards.avgTicket),

        helper: 'Baseado no faturamento bruto',

        icon: Icons.bar_chart_rounded,

        color: const Color(0xFFB084F6),

      ),

      SummaryGridItem(

        label: 'Custos',

        value: _currency(custosTotal),

        helper:

            'Materiais ${_currency(custosMateriais)} ? Compras ${_currency(custosCompras)}',

        icon: Icons.inventory_2_rounded,

        color: const Color(0xFFFF7F6A),

      ),

      SummaryGridItem(

        label: 'Lucro líquido',

        value: _currency(lucroLiquido),

        helper: 'Receita líquida ${_currency(liquido)}',

        icon: Icons.savings_rounded,

        color: const Color(0xFF4CAF50),

      ),

      SummaryGridItem(

        label: 'Margem',

        value: _percent(cards.margin),

        helper: 'Sobre receita líquida',

        icon: Icons.trending_up_rounded,

        color: const Color(0xFF46D0E6),

      ),

    ];

  }





  List<Widget> _dashboardSections(

    BuildContext context,

    FinanceDashboardModel dashboard,

    void Function(String status) onStatusTap,

  ) {

    final sections = <Widget>[

      SummaryGrid(items: _summaryItems(context, dashboard)),

      const SizedBox(height: 12),

      _CostBreakdownCard(

        cards: dashboard.cards,

        currencyBuilder: _currency,

        percentBuilder: _percent,

      ),

    ];

    if (dashboard.purchaseApprovals.hasData) {

      sections.add(const SizedBox(height: 16));

      sections.add(

        _PurchaseApprovalsRow(

          approvals: dashboard.purchaseApprovals,

          onStatusSelected: onStatusTap,

        ),

      );

    }

    sections.add(const SizedBox(height: 20));

    sections.add(

      PaymentMethodChart(

        data: dashboard.paymentsByMethod

            .map(

              (item) => PaymentMethodChartData(

                label: _methodLabel(item.method),

                gross: item.gross,

                fees: item.fees,

                net: item.net,

              ),

            )

            .toList(),

        currencyBuilder: _currency,

      ),

    );

    sections.add(const SizedBox(height: 20));

    sections.add(_AgingSections(data: dashboard));

    sections.add(const SizedBox(height: 20));

    sections.add(

      PurchasesSummaryCard(

        data: dashboard.purchases,

        currencyBuilder: _currency,

      ),

    );

    return sections;

  }



  Future<void> _openAllocationSheet(BuildContext context) async {

    final base = controller.selectedMonth.value;

    DateTime from = DateTime(base.year, base.month, 1);

    DateTime to = DateTime(base.year, base.month + 1, 0);

    final categoriesCtrl = TextEditingController();

    bool submitting = false;



    Future<void> pickRange(BuildContext ctx, StateSetter setState) async {

      final picked = await showDateRangePicker(

        context: ctx,

        initialDateRange: DateTimeRange(start: from, end: to),

        firstDate: DateTime(base.year - 2, 1, 1),

        lastDate: DateTime(base.year + 1, 12, 31),

        locale: const Locale('pt', 'BR'),

      );

      if (picked != null) {

        setState(() {

          from = DateTime(

            picked.start.year,

            picked.start.month,

            picked.start.day,

          );

          to = DateTime(picked.end.year, picked.end.month, picked.end.day);

        });

      }

    }



    final sheetFuture = showModalBottomSheet<void>(

      context: context,

      isScrollControlled: true,

      backgroundColor: context.themeSurface,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (sheetCtx) {

        return StatefulBuilder(

          builder: (ctx, setState) {

            final rangeLabel =

                '${DateFormat('dd/MM/yyyy').format(from)} - ${DateFormat('dd/MM/yyyy').format(to)}';

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

                  const Text(

                    'Ratear custos indiretos',

                    style: TextStyle(

                      color: Colors.white,

                      fontWeight: FontWeight.w600,

                      fontSize: 18,

                    ),

                  ),

                  const SizedBox(height: 12),

                  Text(

                    'Informe o periodo e, se necessario, categorias a serem rateadas.',

                    style: TextStyle(color: context.themeTextSubtle),

                  ),

                  const SizedBox(height: 16),

                  ListTile(

                    contentPadding: EdgeInsets.zero,

                    leading: const Icon(Icons.date_range, color: Colors.white70),

                    title: Text(

                      rangeLabel,

                      style: const TextStyle(color: Colors.white),

                    ),

                    subtitle: const Text(

                      'Toque para alterar o intervalo',

                      style: TextStyle(color: Colors.white54),

                    ),

                    onTap: () => pickRange(ctx, setState),

                  ),

                  const SizedBox(height: 12),

                  TextField(

                    controller: categoriesCtrl,

                    decoration: const InputDecoration(

                      labelText: 'Categorias (opcional, separe por virgula)',

                      prefixIcon: Icon(Icons.category_outlined),

                    ),

                  ),

                  const SizedBox(height: 20),

                  Row(

                    children: [

                      Expanded(

                        child: OutlinedButton(

                          onPressed:

                              submitting ? null : () => Navigator.of(ctx).pop(),

                          child: const Text('Cancelar'),

                        ),

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: ElevatedButton(

                          onPressed: submitting

                              ? null

                              : () async {

                                setState(() => submitting = true);

                                final categories =

                                    categoriesCtrl.text

                                        .split(',')

                                        .map((e) => e.trim())

                                        .where((e) => e.isNotEmpty)

                                        .toList();

                                await controller.allocateIndirectCosts(

                                  from: from,

                                  to: to,

                                  categories: categories,

                                );

                                if (ctx.mounted) Navigator.of(ctx).pop();

                              },

                          child: submitting

                              ? const SizedBox(

                                width: 18,

                                height: 18,

                                child: CircularProgressIndicator(strokeWidth: 2),

                              )

                              : const Text('Executar rateio'),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            );

          },

        );

      },

    );



    await sheetFuture;

    await Future<void>.delayed(const Duration(milliseconds: 50));

    categoriesCtrl.dispose();

  }

}



class _PurchaseApprovalsRow extends StatelessWidget {

  const _PurchaseApprovalsRow({

    required this.approvals,

    required this.onStatusSelected,

  });



  final FinanceDashboardApprovalsSummary approvals;

  final void Function(String status)? onStatusSelected;



  @override

  Widget build(BuildContext context) {

    final cards = [

      _ApprovalCardData(

        label: 'Pendentes',

        value: approvals.pending,

        color: Colors.orangeAccent,

        status: 'pending',

      ),

      _ApprovalCardData(

        label: 'Aprovadas',

        value: approvals.approved,

        color: Colors.tealAccent,

        status: 'approved',

      ),

      _ApprovalCardData(

        label: 'Pedidos',

        value: approvals.ordered,

        color: Colors.lightBlueAccent,

        status: 'ordered',

      ),

      _ApprovalCardData(

        label: 'Recebidas',

        value: approvals.received,

        color: Colors.greenAccent,

        status: 'received',

      ),

    ];



    return Wrap(

      spacing: 12,

      runSpacing: 12,

      children: cards.map((card) {

        return _ApprovalStatCard(

          data: card,

          onTap:

              onStatusSelected == null

                  ? null

                  : () => onStatusSelected!(card.status),

        );

      }).toList(),

    );

  }

}



class _ApprovalCardData {

  const _ApprovalCardData({

    required this.label,

    required this.value,

    required this.color,

    required this.status,

  });



  final String label;

  final int value;

  final Color color;

  final String status;

}



class _ApprovalStatCard extends StatelessWidget {

  const _ApprovalStatCard({required this.data, this.onTap});



  final _ApprovalCardData data;

  final VoidCallback? onTap;



  @override

  Widget build(BuildContext context) {

    final card = Container(

      width: 180,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: context.themeSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: context.themeBorder),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            data.label,

            style: const TextStyle(

              color: Colors.white70,

              fontSize: 12,

              fontWeight: FontWeight.w500,

            ),

          ),

          const SizedBox(height: 8),

          Row(

            children: [

              Text(

                data.value.toString(),

                style: TextStyle(

                  color: data.color,

                  fontSize: 24,

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(width: 6),

              const Icon(Icons.shopping_bag_outlined, color: Colors.white54),

            ],

          ),

        ],

      ),

    );



    if (onTap == null) return card;

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(16),

      child: card,

    );

  }

}



class _FilterRow extends StatelessWidget {

  final FinanceController controller;



  const _FilterRow({required this.controller});



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    controller.periodLabel,

                    style: TextStyle(

                      color: context.themeTextMain,

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    'Atualize o mes ou filtre por centro de custo.',

                    style: TextStyle(color: context.themeTextSubtle),

                  ),

                ],

              ),

            ),

            const SizedBox(width: 12),

            OutlinedButton.icon(

              onPressed: () => controller.pickMonth(context),

              icon: const Icon(Icons.calendar_month_rounded),

              label: Text(

                controller.monthChipLabel,

                style: const TextStyle(fontWeight: FontWeight.w600),

              ),

            ),

          ],

        ),

        const SizedBox(height: 12),

        _CostCenterPicker(controller: controller),

      ],

    );

  }

}



class _CostCenterPicker extends StatelessWidget {

  final FinanceController controller;



  const _CostCenterPicker({required this.controller});



  @override

  Widget build(BuildContext context) {

    return Obx(() {

      final loading = controller.costCentersLoading.value;

      final centers = controller.costCenters.toList(growable: false);

      final hasCenters = centers.isNotEmpty;

      final label = controller.costCenterLabel;

      final hasFilter =

          (controller.selectedCostCenterId.value ?? '').trim().isNotEmpty;

      return OutlinedButton.icon(

        icon: loading

            ? const SizedBox(

              width: 16,

              height: 16,

              child: CircularProgressIndicator(strokeWidth: 2),

            )

            : const Icon(Icons.account_tree_outlined),

        label: Text(

          label,

          overflow: TextOverflow.ellipsis,

        ),

        onPressed:

            loading || (!hasCenters && !hasFilter)

                ? null

                : () => _showPicker(context, centers),

        onLongPress: hasFilter ? () => controller.setCostCenter(null) : null,

      );

    });

  }



  Future<void> _showPicker(

    BuildContext context,

    List<CostCenterModel> centers,

  ) async {

    final selected = controller.selectedCostCenterId.value ?? '';

    final result = await showModalBottomSheet<String?>(

      context: context,

      backgroundColor: context.themeSurface,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (ctx) {

        return SafeArea(

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Padding(

                padding: EdgeInsets.all(16),

                child: Text(

                  'Filtrar por centro de custo',

                  style: TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ),

              RadioListTile<String>(

                value: '',

                groupValue: selected,

                onChanged: (_) => Navigator.of(ctx).pop(''),

                title: const Text('Todos os centros'),

              ),

              const Divider(height: 1),

              Flexible(

                child: ListView.builder(

                  shrinkWrap: true,

                  itemCount: centers.length,

                  itemBuilder: (ctx, index) {

                    final center = centers[index];

                    return RadioListTile<String>(

                      value: center.id,

                      groupValue: selected,

                      onChanged: (_) => Navigator.of(ctx).pop(center.id),

                      title: Text(center.name),

                    );

                  },

                ),

              ),

              const SizedBox(height: 12),

            ],

          ),

        );

      },

    );

    if (result == null) return;

    if (result.isEmpty) {

      await controller.setCostCenter(null);

    } else {

      await controller.setCostCenter(result);

    }

  }

}



class _ShortcutRow extends StatelessWidget {

  final VoidCallback onAuditTap;

  final VoidCallback onForecastTap;

  final VoidCallback onAllocationTap;

  final bool allocationLoading;

  final VoidCallback onReconciliationTap;



  const _ShortcutRow({

    required this.onAuditTap,

    required this.onForecastTap,

    required this.onAllocationTap,

    required this.allocationLoading,

    required this.onReconciliationTap,

  });



  @override

  Widget build(BuildContext context) {

    return Wrap(

      spacing: 12,

      runSpacing: 8,

      children: [

        OutlinedButton.icon(

          onPressed: onAuditTap,

          icon: const Icon(Icons.search_rounded),

          label: const Text('Ir para Auditoria'),

        ),

        OutlinedButton.icon(

          onPressed: onForecastTap,

          icon: const Icon(Icons.monitor_heart_rounded),

          label: const Text('Ver Previsão'),

        ),

        ElevatedButton.icon(

          onPressed: allocationLoading ? null : onAllocationTap,

          icon:

              allocationLoading

                  ? const SizedBox(

                    width: 16,

                    height: 16,

                    child: CircularProgressIndicator(strokeWidth: 2),

                  )

                  : const Icon(Icons.savings_outlined),

          label: const Text('Ratear indiretos'),

        ),

        OutlinedButton.icon(

          onPressed: onReconciliationTap,

          icon: const Icon(Icons.compare_arrows_rounded),

          label: const Text('Reconciliao'),

        ),

      ],

    );

  }

}



class _PlaceholderCard extends StatelessWidget {

  final Widget child;



  const _PlaceholderCard({required this.child});



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),

      decoration: BoxDecoration(

        color: context.themeSurface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: context.themeBorder),

      ),

      child: Center(child: child),

    );

  }

}



class _FinanceAnomaliesSection extends StatelessWidget {

  const _FinanceAnomaliesSection({required this.controller});



  final FinanceController controller;



  @override

  Widget build(BuildContext context) {

    return Obx(() {

      final loading = controller.anomaliesLoading.value;

      final report = controller.anomalies.value;

      final error = controller.anomaliesError.value;



      if (loading && report == null) {

        return _PlaceholderCard(

          child: Column(

            children: const [

              CircularProgressIndicator(),

              SizedBox(height: 12),

              Text('Gerando anomalias financeiras...'),

            ],

          ),

        );

      }



      if (report == null && error.isNotEmpty) {

        return _PlaceholderCard(

          child: Column(

            children: [

              const Icon(Icons.warning_amber_rounded, color: Colors.orange),

              const SizedBox(height: 8),

              Text(error, textAlign: TextAlign.center),

              TextButton(

                onPressed: controller.loadAnomalies,

                child: const Text('Tentar novamente'),

              ),

            ],

          ),

        );

      }



      if (report == null || (!report.hasItems && (report.summary ?? '').isEmpty)) {

        return const SizedBox.shrink();

      }



      final items = report.items;



      return Card(

        color: context.themeSurface,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        child: Padding(

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                children: [

                  const Expanded(

                    child: Text(

                      'Anomalias financeiras',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 18,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                  IconButton(

                    tooltip: 'Recarregar',

                    onPressed: controller.loadAnomalies,

                    icon: const Icon(Icons.refresh, color: Colors.white70),

                  ),

                ],

              ),

              if ((report.summary ?? '').isNotEmpty) ...[

                const SizedBox(height: 4),

                Text(

                  report.summary!,

                  style: TextStyle(color: context.themeTextSubtle),

                ),

                const SizedBox(height: 12),

              ],

              if (items.isEmpty)

                Text(

                  'Nenhuma inconsistência relevante foi sinalizada para o período selecionado.',

                  style: TextStyle(color: context.themeTextSubtle),

                )

              else

                ...items.map(

                  (item) => _FinanceAnomalyTile(data: item),

                ),

            ],

          ),

        ),

      );

    });

  }

}



class _FinanceAnomalyTile extends StatelessWidget {

  const _FinanceAnomalyTile({required this.data});



  final FinanceAnomalyInsight data;



  Color _severityColor(BuildContext context) {

    switch ((data.severity ?? '').toLowerCase()) {

      case 'critical':

      case 'alta':

      case 'high':

        return Colors.redAccent;

      case 'medium':

      case 'media':

        return Colors.orangeAccent;

      case 'low':

      case 'baixa':

        return Colors.blueAccent;

      default:

        return context.themePrimary;

    }

  }



  @override

  Widget build(BuildContext context) {

    final color = _severityColor(context);

    return Container(

      margin: const EdgeInsets.symmetric(vertical: 6),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: Colors.white.withValues(alpha: 0.03),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white10),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Expanded(

                child: Text(

                  data.title,

                  style: const TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

              if ((data.severity ?? '').isNotEmpty)

                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                  decoration: BoxDecoration(

                    color: color.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(20),

                  ),

                  child: Text(

                    (data.severity ?? '').toUpperCase(),

                    style: TextStyle(color: color, fontSize: 12),

                  ),

                ),

            ],

          ),

          const SizedBox(height: 6),

          Text(

            data.description,

            style: const TextStyle(color: Colors.white70),

          ),

          if ((data.recommendation ?? '').isNotEmpty) ...[

            const SizedBox(height: 8),

            Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 16),

                const SizedBox(width: 6),

                Expanded(

                  child: Text(

                    data.recommendation!,

                    style: const TextStyle(color: Colors.white70),

                  ),

                ),

              ],

            ),

          ],

          if (data.impactValue != null) ...[

            const SizedBox(height: 6),

            Text(

              'Impacto estimado: R\$ ',

              style: const TextStyle(color: Colors.white60, fontSize: 12),

            ),

          ],

        ],

      ),

    );

  }

}





class _AgingSections extends StatelessWidget {

  final FinanceDashboardModel data;



  const _AgingSections({required this.data});



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (context, constraints) {

        final receivablesCard = AgingSummaryCard(

          title: 'Recebíveis',

          data: data.receivables,

          accent: context.themePrimary,

          currencyBuilder: _currency,

        );

        final payablesCard = AgingSummaryCard(

          title: 'Pagáveis',

          data: data.payables,

          accent: const Color(0xFFFF6B6B),

          currencyBuilder: _currency,

        );



        if (constraints.maxWidth < 900) {

          return Column(

            children: [

              receivablesCard,

              const SizedBox(height: 16),

              payablesCard,

            ],

          );

        }



        return Row(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Expanded(child: receivablesCard),

            const SizedBox(width: 16),

            Expanded(child: payablesCard),

          ],

        );

      },

    );

  }

}



class _CostBreakdownCard extends StatelessWidget {

  const _CostBreakdownCard({

    required this.cards,

    required this.currencyBuilder,

    required this.percentBuilder,

  });



  final FinanceDashboardCards cards;

  final String Function(double value) currencyBuilder;

  final String Function(double value) percentBuilder;



  @override

  Widget build(BuildContext context) {

    final custosMateriais = cards.materialCost;

    final custosCompras = cards.purchaseCost;

    final receitaLiquida = cards.netCollected;

    final receitaBruta = cards.grossCollected;

    final lucroLiquido = receitaLiquida - (custosMateriais + custosCompras);



    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: context.themeSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.white10),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            'Resumo financeiro',

            style: TextStyle(

              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize: 16,

            ),

          ),

          const SizedBox(height: 10),

          _CostRow(

            label: 'Receita bruta',

            value: currencyBuilder(receitaBruta),

            icon: Icons.trending_up,

          ),

          _CostRow(

            label: 'Receita líquida',

            value: currencyBuilder(receitaLiquida),

            icon: Icons.payments_outlined,

          ),

          const Divider(height: 20),

          _CostRow(

            label: 'Materiais',

            value: currencyBuilder(custosMateriais),

            icon: Icons.handyman_outlined,

          ),

          _CostRow(

            label: 'Compras (ordered/received)',

            value: currencyBuilder(custosCompras),

            icon: Icons.shopping_bag_outlined,

          ),

          _CostRow(

            label: 'Margem',

            value: percentBuilder(cards.margin),

            icon: Icons.percent,

          ),

          const Divider(height: 20),

          _CostRow(

            label: 'Lucro líquido',

            value: currencyBuilder(lucroLiquido),

            icon: Icons.savings_rounded,

            highlight: true,

          ),

        ],

      ),

    );

  }

}



class _CostRow extends StatelessWidget {

  const _CostRow({

    required this.label,

    required this.value,

    required this.icon,

    this.highlight = false,

  });



  final String label;

  final String value;

  final IconData icon;

  final bool highlight;



  @override

  Widget build(BuildContext context) {

    final color =

        highlight ? context.themeGreen : Colors.white.withValues(alpha: 0.9);

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 6),

      child: Row(

        children: [

          Icon(icon, color: color, size: 18),

          const SizedBox(width: 8),

          Expanded(

            child: Text(

              label,

              style: TextStyle(color: color),

            ),

          ),

          Text(

            value,

            style: TextStyle(

              color: color,

              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,

            ),

          ),

        ],

      ),

    );

  }

}



String _methodLabel(String method) {

  switch (method.toLowerCase()) {

    case 'pix':

      return 'PIX';

    case 'cash':

      return 'Dinheiro';

    case 'card':

      return 'Carto';

    case 'bank_transfer':

    case 'transfer':

      return 'Transferncia';

    case 'boleto':

      return 'Boleto';

    default:

      return method.isEmpty ? 'Outro' : method.toUpperCase();

  }

}



class _AuditSection extends StatelessWidget {

  final FinanceController controller;



  const _AuditSection({required this.controller});



  @override

  Widget build(BuildContext context) {

    final audit = controller.audit.value;

    final loading = controller.auditLoading.value;

    final filter = controller.auditFilter.value;



    final issues = _filteredIssues(audit, filter);



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

          Row(

            children: [

              const Expanded(

                child: Text(

                  'Auditoria financeira',

                  style: TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.w600,

                    fontSize: 16,

                  ),

                ),

              ),

              IconButton(

                tooltip: 'Atualizar auditoria',

                onPressed: controller.auditLoading.value

                    ? null

                    : controller.loadAudit,

                icon: const Icon(Icons.refresh_rounded),

              ),

            ],

          ),

          const SizedBox(height: 8),

          Text(

            'Revise inconsistências detectadas em OSs e compras.',

            style: TextStyle(color: context.themeTextSubtle),

          ),

          const SizedBox(height: 12),

          Wrap(

            spacing: 8,

            runSpacing: 4,

            children: [

              _AuditFilterChip(

                label: 'Todos',

                value: 'all',

                selected: filter == 'all',

                onSelected: () => controller.setAuditFilter('all'),

              ),

              _AuditFilterChip(

                label: 'OS',

                value: 'orders',

                selected: filter == 'orders',

                onSelected: () => controller.setAuditFilter('orders'),

              ),

              _AuditFilterChip(

                label: 'Compras',

                value: 'purchases',

                selected: filter == 'purchases',

                onSelected: () => controller.setAuditFilter('purchases'),

              ),

            ],

          ),

          const SizedBox(height: 16),

          if (loading)

            const Center(

              child: Padding(

                padding: EdgeInsets.symmetric(vertical: 24),

                child: CircularProgressIndicator(),

              ),

            )

          else if (issues.isEmpty)

            Padding(

              padding: const EdgeInsets.symmetric(vertical: 12),

              child: Text(

                'Nenhuma inconsistência encontrada para o filtro atual.',

                style: TextStyle(color: context.themeTextSubtle),

              ),

            )

          else

            Column(

              children: issues

                  .map(

                    (issue) => Padding(

                      padding: const EdgeInsets.only(bottom: 12),

                      child: _AuditIssueCard(issue: issue),

                    ),

                  )

                  .toList(),

            ),

        ],

      ),

    );

  }



  List<FinanceAuditIssue> _filteredIssues(

    FinanceAuditModel? audit,

    String filter,

  ) {

    if (audit == null) return const [];

    if (filter == 'orders') return audit.orders;

    if (filter == 'purchases') return audit.purchases;

    return [...audit.orders, ...audit.purchases];

  }

}



class _AuditFilterChip extends StatelessWidget {

  final String label;

  final String value;

  final bool selected;

  final VoidCallback onSelected;



  const _AuditFilterChip({

    required this.label,

    required this.value,

    required this.selected,

    required this.onSelected,

  });



  @override

  Widget build(BuildContext context) {

    return ChoiceChip(

      label: Text(label),

      labelStyle: const TextStyle(color: Colors.white),

      selected: selected,

      onSelected: (_) => onSelected(),

      selectedColor: context.themePrimary.withValues(alpha: .2),

      backgroundColor: context.themeSurfaceAlt,

    );

  }

}



class _AuditIssueCard extends StatelessWidget {

  final FinanceAuditIssue issue;



  const _AuditIssueCard({required this.issue});



  @override

  Widget build(BuildContext context) {

    final isOrder = issue.type.toLowerCase().contains('order');

    final badgeColor = isOrder ? context.themeInfo : context.themeWarning;

    final date = issue.createdAt;

    final dateLabel =

        date != null ? DateFormat('dd/MM HH:mm').format(date.toLocal()) : null;

    final delta = issue.deltaPercent;



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

          Row(

            children: [

              Container(

                padding:

                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                decoration: BoxDecoration(

                  color: badgeColor.withValues(alpha: .2),

                  borderRadius: BorderRadius.circular(999),

                ),

                child: Text(

                  isOrder ? 'OS' : 'Compra',

                  style: TextStyle(

                    color: badgeColor,

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ),

              if (dateLabel != null) ...[

                const SizedBox(width: 8),

                Text(

                  dateLabel,

                  style: TextStyle(color: context.themeTextSubtle, fontSize: 12),

                ),

              ],

              const Spacer(),

              TextButton(

                onPressed: () => _openReference(issue),

                child: Text(isOrder ? 'Ver OS' : 'Ver compra'),

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

          const SizedBox(height: 4),

          Text(

            'Ref: ${issue.reference.isNotEmpty ? issue.reference : issue.id}',

            style: TextStyle(color: context.themeTextSubtle, fontSize: 12),

          ),

          if (delta != null) ...[

            const SizedBox(height: 4),

            Text(

              'Variação: ${delta.toStringAsFixed(1)}%',

              style: TextStyle(

                color: delta >= 0 ? Colors.redAccent : Colors.lightBlueAccent,

              ),

            ),

          ],

        ],

      ),

    );

  }



  void _openReference(FinanceAuditIssue issue) {

    final reference = issue.id.isNotEmpty ? issue.id : issue.reference;

    if (issue.type.toLowerCase().contains('order')) {

      Get.to<OrderModel?>(

        () => const OrderDetailPage(),

        binding: OrderDetailBindings(orderId: reference),

      );

    } else {

      Get.toNamed('/purchases', arguments: {'initialFilter': reference});

    }

  }

}



class _ForecastSection extends StatelessWidget {

  const _ForecastSection({

    required this.forecast,

    required this.isLoading,

    required this.selectedDays,

    required this.onDaysChanged,

    required this.onRefresh,

  });



  final FinanceForecastModel? forecast;

  final bool isLoading;

  final int selectedDays;

  final void Function(int days) onDaysChanged;

  final Future<void> Function() onRefresh;



  @override

  Widget build(BuildContext context) {

    final data = forecast;

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

          Row(

            children: [

              const Expanded(

                child: Text(

                  'Previsão de fluxo',

                  style: TextStyle(

                    color: Colors.white,

                    fontWeight: FontWeight.w600,

                    fontSize: 16,

                  ),

                ),

              ),

              IconButton(

                tooltip: 'Atualizar Previsão',

                onPressed: isLoading ? null : onRefresh,

                icon: const Icon(Icons.refresh_rounded),

              ),

            ],

          ),

          const SizedBox(height: 8),

          Text(

            'Simulação de recebveis, pagáveis e projees para os próximos dias.',

            style: TextStyle(color: context.themeTextSubtle),

          ),

          const SizedBox(height: 12),

          Wrap(

            spacing: 8,

            children: [15, 30, 60]

                .map(

                  (days) => ChoiceChip(

                    label: Text('$days dias'),

                    selected: selectedDays == days,

                    onSelected: (_) => onDaysChanged(days),

                  ),

                )

                .toList(),

          ),

          const SizedBox(height: 12),

          if (isLoading)

            const Center(

              child: Padding(

                padding: EdgeInsets.symmetric(vertical: 24),

                child: CircularProgressIndicator(),

              ),

            )

          else if (data == null || data.timeline.isEmpty)

            Padding(

              padding: const EdgeInsets.symmetric(vertical: 12),

              child: Text(

                'Sem dados suficientes para montar a Previsão.',

                style: TextStyle(color: context.themeTextSubtle),

              ),

            )

          else

            _ForecastHeatMap(entries: data.timeline),

        ],

      ),

    );

  }

}



class _ForecastHeatMap extends StatelessWidget {

  final List<FinanceForecastTimelineEntry> entries;



  const _ForecastHeatMap({required this.entries});



  @override

  Widget build(BuildContext context) {

    final maxAbsNet = entries.fold<double>(

      0,

      (prev, e) => prev > e.net.abs() ? prev : e.net.abs(),

    );

    final maxMetric = entries.fold<double>(

      0,

      (prev, e) => [

        e.receivables.abs(),

        e.payables.abs(),

        e.projectedOrders.abs(),

        e.projectedPurchases.abs(),

      ].fold(prev, (p, v) => p > v ? p : v),

    );



    return SingleChildScrollView(

      scrollDirection: Axis.horizontal,

      child: Row(

        children: entries

            .map(

              (entry) => _ForecastDayTile(

                entry: entry,

                maxNet: maxAbsNet == 0 ? 1 : maxAbsNet,

                maxMetric: maxMetric == 0 ? 1 : maxMetric,

              ),

            )

            .toList(),

      ),

    );

  }

}



class _ForecastDayTile extends StatelessWidget {

  final FinanceForecastTimelineEntry entry;

  final double maxNet;

  final double maxMetric;



  const _ForecastDayTile({

    required this.entry,

    required this.maxNet,

    required this.maxMetric,

  });



  @override

  Widget build(BuildContext context) {

    final netColor = _netColor(entry.net);

    final dateLabel = DateFormat('dd/MM').format(entry.date.toLocal());



    return Container(

      width: 90,

      margin: const EdgeInsets.only(right: 8),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color: netColor,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.white12),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            dateLabel,

            style: const TextStyle(

              color: Colors.white,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 4),

          Text(

            _currency(entry.net),

            style: TextStyle(

              color: entry.net >= 0 ? Colors.white : Colors.white70,

              fontSize: 12,

            ),

          ),

          const SizedBox(height: 8),

          _MetricBar(

            label: 'Receb.',

            value: entry.receivables,

            max: maxMetric,

            color: Colors.tealAccent,

          ),

          _MetricBar(

            label: 'Pag.',

            value: entry.payables,

            max: maxMetric,

            color: Colors.orangeAccent,

          ),

          _MetricBar(

            label: 'Proj. OS',

            value: entry.projectedOrders,

            max: maxMetric,

            color: Colors.blueAccent,

          ),

          _MetricBar(

            label: 'Proj. Cp.',

            value: entry.projectedPurchases,

            max: maxMetric,

            color: Colors.purpleAccent,

          ),

        ],

      ),

    );

  }



  Color _netColor(double net) {

    if (net == 0) return Colors.white10;

    final base = net >= 0 ? Colors.greenAccent : Colors.redAccent;

    final intensity = (net.abs() / maxNet).clamp(0.2, 1.0);

    return base.withValues(alpha: 0.15 + 0.45 * intensity);

  }

}



class _MetricBar extends StatelessWidget {

  final String label;

  final double value;

  final double max;

  final Color color;



  const _MetricBar({

    required this.label,

    required this.value,

    required this.max,

    required this.color,

  });



  @override

  Widget build(BuildContext context) {

    final ratio = (value.abs() / max).clamp(0.0, 1.0);

    return Padding(

      padding: const EdgeInsets.only(bottom: 4),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            label,

            style: TextStyle(color: context.themeTextSubtle, fontSize: 10),

          ),

          const SizedBox(height: 2),

          ClipRRect(

            borderRadius: BorderRadius.circular(999),

            child: LinearProgressIndicator(

              minHeight: 4,

              value: ratio.isNaN ? 0 : ratio,

              backgroundColor: Colors.white10,

              valueColor: AlwaysStoppedAnimation<Color>(color),

            ),

          ),

        ],

      ),

    );

  }

}



class FinanceAuditPage extends StatelessWidget {

  const FinanceAuditPage({super.key});



  @override

  Widget build(BuildContext context) {

    final controller = Get.find<FinanceController>();

    return Scaffold(

      appBar: AppBar(

        title: const Text('Auditoria financeira'),

        backgroundColor: context.themeSurface,

      ),

      body: SafeArea(

        child: RefreshIndicator(

          onRefresh: controller.loadAudit,

          color: context.themePrimary,

          child: ListView(

            padding: const EdgeInsets.all(16),

            children: [

              _AuditSection(controller: controller),

            ],

          ),

        ),

      ),

    );

  }

}



class FinanceForecastPage extends StatelessWidget {

  const FinanceForecastPage({super.key});



  @override

  Widget build(BuildContext context) {

    final controller = Get.find<FinanceController>();

    return Scaffold(

      appBar: AppBar(

        title: const Text('Previsão de fluxo'),

        backgroundColor: context.themeSurface,

      ),

      body: SafeArea(

        child: RefreshIndicator(

          onRefresh: controller.loadForecast,

          color: context.themePrimary,

          child: Obx(

            () => ListView(

              padding: const EdgeInsets.all(16),

              children: [

                _ForecastSection(

                  forecast: controller.forecast.value,

                  isLoading: controller.forecastLoading.value,

                  selectedDays: controller.forecastDays.value,

                  onDaysChanged: controller.setForecastDays,

                  onRefresh: controller.loadForecast,

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}




































