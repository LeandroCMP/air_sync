import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/ui/widgets/ai_loading_overlay.dart';
import 'package:air_sync/application/utils/formatters/license_plate_input_formatter.dart';
import 'package:air_sync/application/utils/formatters/money_formatter.dart';
import 'package:air_sync/application/utils/formatters/upper_case_input_formatter.dart';
import 'package:air_sync/modules/fleet/fleet_history_bindings.dart';
import 'package:air_sync/modules/fleet/fleet_history_page.dart';
import 'package:air_sync/models/fleet_vehicle_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:air_sync/application/core/form_validator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'fleet_controller.dart';

class FleetPage extends GetView<FleetController> {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthServiceApplication>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Frota', style: TextStyle(color: Colors.white)),
        actions: [
          Obx(() {
            final canUseInsights =
                auth.user.value?.hasPermission('fleet.read') ?? false;
            if (!canUseInsights) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Recomendações',
                  onPressed: () => _showRecommendations(context, controller),
                  icon: const Icon(Icons.auto_awesome),
                ),
                IconButton(
                  tooltip: 'Pergunte à IA',
                  onPressed: () => _openFleetChat(context, controller),
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openVehicleForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Obx(() {
          final isLoading = controller.isLoading.value;
          final filter = controller.statusFilter.value;
          final items = controller.filteredItems;
          final summaryEntries = _buildFleetSummaryEntries(controller.items);
          final hasAny = controller.items.isNotEmpty;
          final hasSearch = controller.search.value.isNotEmpty;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: _FleetSearchField(controller: controller)),
                    const SizedBox(width: 8),
                    _SortMenu(controller: controller),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Alternar ordem',
                      onPressed: controller.toggleOrder,
                      icon: Icon(
                        controller.order.value == 'asc'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.load,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      if (summaryEntries.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _FleetSummaryRow(
                              entries: summaryEntries,
                              selectedKey: filter,
                              onSelect: controller.setStatusFilter,
                            ),
                          ),
                        ),
                      if (items.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final vehicle = items[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                index == items.length - 1 ? 120 : 16,
                              ),
                              child: _FleetCard(
                                vehicle: vehicle,
                                controller: controller,
                                onTap:
                                    () => _openVehicleActions(context, vehicle),
                                onEdit:
                                    () => _openVehicleForm(
                                      context,
                                      vehicle: vehicle,
                                    ),
                                onHistory: () => _openHistory(context, vehicle),
                              ),
                            );
                          }, childCount: items.length),
                        )
                      else
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _FleetEmptyState(
                            hasAnyVehicles: hasAny,
                            hasSearch: hasSearch,
                            onClearFilters: () {
                              if (controller.statusFilter.value != 'all') {
                                controller.setStatusFilter('all');
                              }
                              if (hasSearch) {
                                controller.clearSearch();
                              }
                            },
                            onCreate: () => _openVehicleForm(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _openVehicleActions(BuildContext context, FleetVehicleModel vehicle) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.fact_check_outlined,
                label: 'Check',
                onTap: () {
                  Get.back();
                  _openCheckDialog(context, vehicle);
                },
              ),
              _ActionTile(
                icon: Icons.local_gas_station_outlined,
                label: 'Abastecimento',
                onTap: () {
                  Get.back();
                  _openFuelDialog(context, vehicle);
                },
              ),
              _ActionTile(
                icon: Icons.build_outlined,
                label: 'Manutenção',
                onTap: () {
                  Get.back();
                  _openMaintenanceDialog(context, vehicle);
                },
              ),
              _ActionTile(
                icon: Icons.history,
                label: 'Histórico',
                onTap: () {
                  Get.back();
                  _openHistory(context, vehicle);
                },
              ),
              _ActionTile(
                icon: Icons.edit_outlined,
                label: 'Editar',
                onTap: () {
                  Get.back();
                  _openVehicleForm(context, vehicle: vehicle);
                },
              ),
              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Excluir',
                isDestructive: true,
                onTap: () async {
                  Get.back();
                  final ok = await Get.dialog<bool>(
                    AlertDialog(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      title: const Text(
                        'Excluir veículo',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Tem certeza que deseja excluir?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await controller.deleteVehicle(vehicle.id);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openCheckDialog(BuildContext context, FleetVehicleModel vehicle) {
    final odoCtrl = TextEditingController(text: vehicle.odometer.toString());
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final fuelLevel = 50.obs;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registrar check',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator:
                        (v) => FormValidators.validateNumber(
                          v,
                          fieldName: 'Odômetro',
                          positive: true,
                        ),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Odômetro',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nível de combustível',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${fuelLevel.value}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Slider(
                      value: fuelLevel.value.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${fuelLevel.value}%',
                      onChanged: (value) => fuelLevel.value = value.round(),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final odo =
                                  int.tryParse(odoCtrl.text.trim()) ?? 0;
                              if (odo < vehicle.odometer) {
                                Get.snackbar(
                                  'Frota',
                                  'Odômetro não pode regredir',
                                );
                                return;
                              }
                              await controller.doCheck(
                                vehicle,
                                odometer: odo,
                                fuelLevel: fuelLevel.value,
                                notes:
                                    notesCtrl.text.trim().isEmpty
                                        ? null
                                        : notesCtrl.text.trim(),
                              );
                              if (sheetCtx.mounted) {
                                Navigator.of(
                                  sheetCtx,
                                  rootNavigator: true,
                                ).pop();
                              }
                            },
                            child: Text(
                              'Salvar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.themeGray,
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
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
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

  void _openFuelDialog(BuildContext context, FleetVehicleModel vehicle) {
    final odoCtrl = TextEditingController(text: vehicle.odometer.toString());
    final litersCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    final fuelType = 'gasoline'.obs;
    final isSaving = false.obs;

    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registrar abastecimento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: litersCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator:
                              (value) => FormValidators.validateNumber(
                                value,
                                fieldName: 'Litros',
                                positive: true,
                              ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Litros',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                          inputFormatters: const [MoneyInputFormatter()],
                          validator: (value) {
                            final parsed = parseCurrencyPtBr(value);
                            if (parsed == null || parsed <= 0) {
                              return 'Informe um valor válido';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Valor total',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: fuelType.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de combustível',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      dropdownColor: sheetCtx.themeDark,
                      items: [
                        DropdownMenuItem(
                          value: 'gasoline',
                          child: Text('Gasolina'),
                        ),
                        DropdownMenuItem(
                          value: 'ethanol',
                          child: Text('Etanol'),
                        ),
                        DropdownMenuItem(
                          value: 'diesel',
                          child: Text('Diesel'),
                        ),
                        DropdownMenuItem(
                          value: 'gnv',
                          child: Text('GNV'),
                        ),
                        DropdownMenuItem(
                          value: 'electric',
                          child: Text('Elétrico'),
                        ),
                      ],
                      onChanged:
                          (value) => fuelType.value = value ?? 'gasoline',
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Selecione o tipo de combustível'
                                  : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: odoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator:
                        (value) => FormValidators.validateNumber(
                          value,
                          fieldName: 'Odômetro',
                          positive: true,
                        ),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Odômetro',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sheetCtx.themeGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed:
                                  isSaving.value
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        final liters =
                                            double.tryParse(
                                              litersCtrl.text.trim().replaceAll(
                                                ',',
                                                '.',
                                              ),
                                            ) ??
                                            0;
                                        final price =
                                            parseCurrencyPtBr(priceCtrl.text) ??
                                            0;
                                        final odo =
                                            int.tryParse(odoCtrl.text.trim()) ??
                                            0;
                                        if (liters <= 0 || price <= 0) return;
                                        if (odo < vehicle.odometer) {
                                          Get.snackbar(
                                            'Frota',
                                            'Odômetro não pode regredir',
                                          );
                                          return;
                                        }
                                        isSaving.value = true;
                                        try {
                                          await controller.doFuel(
                                            vehicle,
                                            liters: liters,
                                            price: price,
                                            fuelType: fuelType.value,
                                            odometer: odo,
                                          );
                                          if (sheetCtx.mounted) {
                                            Navigator.of(
                                              sheetCtx,
                                              rootNavigator: true,
                                            ).pop();
                                          }
                                        } finally {
                                          isSaving.value = false;
                                        }
                                      },
                              child:
                                  isSaving.value
                                      ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        'Salvar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: sheetCtx.themeGray,
                                        ),
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
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ).whenComplete(() {
      odoCtrl.dispose();
      litersCtrl.dispose();
      priceCtrl.dispose();
    });
  }

  void _openMaintenanceDialog(BuildContext context, FleetVehicleModel vehicle) {
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '0');
    final odoCtrl = TextEditingController(text: vehicle.odometer.toString());
    final formKey = GlobalKey<FormState>();
    final isSaving = false.obs;

    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetCtx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registrar manutenção',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                          validator:
                              (value) => FormValidators.validateNotEmpty(
                                value,
                                fieldName: 'Descrição',
                              ),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                          inputFormatters: const [MoneyInputFormatter()],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final parsed = parseCurrencyPtBr(value);
                            if (parsed == null || parsed < 0) {
                              return 'Informe um custo válido';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Custo (opcional)',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: odoCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator:
                              (value) => FormValidators.validateNumber(
                                value,
                                fieldName: 'Odômetro',
                                positive: true,
                              ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Odômetro',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sheetCtx.themeGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed:
                                  isSaving.value
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        final desc = descCtrl.text.trim();
                                        final cost =
                                            costCtrl.text.trim().isEmpty
                                                ? null
                                                : parseCurrencyPtBr(
                                                  costCtrl.text,
                                                );
                                        final odo =
                                            int.tryParse(odoCtrl.text.trim()) ??
                                            0;
                                        if (odo < vehicle.odometer) {
                                          Get.snackbar(
                                            'Frota',
                                            'Odômetro não pode regredir',
                                          );
                                          return;
                                        }
                                        isSaving.value = true;
                                        try {
                                          await controller.doMaintenance(
                                            vehicle,
                                            description: desc,
                                            cost: cost,
                                            odometer: odo,
                                          );
                                          if (sheetCtx.mounted) {
                                            Navigator.of(
                                              sheetCtx,
                                              rootNavigator: true,
                                            ).pop();
                                          }
                                        } finally {
                                          isSaving.value = false;
                                        }
                                      },
                              child:
                                  isSaving.value
                                      ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        'Salvar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: sheetCtx.themeGray,
                                        ),
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
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ).whenComplete(() {
      descCtrl.dispose();
      costCtrl.dispose();
      odoCtrl.dispose();
    });
  }

  void _openVehicleForm(BuildContext context, {dynamic vehicle}) {
    final isEdit = vehicle != null;
    final plateCtrl = TextEditingController(
      text: isEdit ? vehicle.plate.toString().toUpperCase() : '',
    );
    final modelCtrl = TextEditingController(
      text: isEdit ? (vehicle.model?.toString().toUpperCase() ?? '') : '',
    );
    final yearCtrl = TextEditingController(
      text: isEdit && vehicle.year != null ? vehicle.year.toString() : '',
    );
    final odoCtrl = TextEditingController(
      text: isEdit ? vehicle.odometer.toString() : '0',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      useRootNavigator: true,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Editar veículo' : 'Novo veículo',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [LicensePlateInputFormatter()],
                    validator:
                        (v) => FormValidators.validateNotEmpty(
                          v,
                          fieldName: 'Placa',
                        ),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: modelCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [UpperCaseTextFormatter()],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Modelo (opcional)',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator:
                              (v) => FormValidators.validateOptionalNumber(
                                v,
                                fieldName: 'Ano',
                                positive: true,
                              ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Ano (opcional)',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: odoCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          validator:
                              (v) => FormValidators.validateNumber(
                                v,
                                fieldName: 'Odômetro',
                                positive: true,
                              ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Odômetro',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final normalizedPlate =
                                  plateCtrl.text.trim().toUpperCase();
                              plateCtrl.text = normalizedPlate;
                              final odometer =
                                  int.tryParse(odoCtrl.text.trim()) ?? 0;
                              final year =
                                  yearCtrl.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(yearCtrl.text.trim());
                              final modelText = modelCtrl.text.trim();
                              final model =
                                  modelText.isEmpty ? null : modelText.toUpperCase();
                              final ctrl = Get.find<FleetController>();
                              if (isEdit) {
                                await ctrl.updateVehicle(
                                  vehicle.id,
                                  plate: normalizedPlate,
                                  model: model,
                                  year: year,
                                  odometer: odometer,
                                );
                              } else {
                                await ctrl.createVehicle(
                                  plate: normalizedPlate,
                                  model: model,
                                  year: year,
                                  odometer: odometer,
                                );
                              }
                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop();
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
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
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

  void _openHistory(BuildContext context, FleetVehicleModel vehicle) {
    final plate = vehicle.plate.trim();
    final model = (vehicle.model ?? '').trim();
    final historyTitle =
        plate.isNotEmpty ? plate : (model.isNotEmpty ? model : 'Veículo');
    Get.to(
      () => const FleetHistoryPage(),
      binding: FleetHistoryBindings(),
      arguments: {'vehicleId': vehicle.id, 'title': historyTitle},
    );
  }
}

Future<void> _showRecommendations(
  BuildContext context,
  FleetController controller,
) async {
  final hideOverlay = AiLoadingOverlay.show(
    context,
    message: 'Consultando recomendações inteligentes...',
  );
  final recs = await controller.fetchRecommendations();
  hideOverlay();
  if (recs.isEmpty || !context.mounted) return;
  showModalBottomSheet(
    context: context,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recomendações inteligentes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recs.map(
            (rec) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((rec.priority ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text(rec.priority!.toUpperCase()),
                        backgroundColor:
                            Colors.orange.withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    rec.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _openFleetChat(
  BuildContext context,
  FleetController controller,
) async {
  final questionCtrl = TextEditingController();
  String answer = '';
  bool sending = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.themeDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pergunte à IA sobre a frota',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: questionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Pergunta',
                hintText: 'Ex: como reduzir custos da frota?',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sending
                    ? null
                    : () async {
                        if (questionCtrl.text.trim().isEmpty) return;
                        setState(() => sending = true);
                        final hideOverlay = AiLoadingOverlay.show(
                          ctx,
                          message: 'Perguntando para a IA da frota...',
                        );
                        try {
                          final response =
                              await controller.askAssistant(questionCtrl.text.trim());
                          if (ctx.mounted) {
                            setState(() {
                              sending = false;
                              answer = response?.answer ?? '';
                            });
                          }
                        } finally {
                          hideOverlay();
                        }
                      },
                icon: const Icon(Icons.chat),
                label: Text(sending ? 'Consultando...' : 'Enviar'),
              ),
            ),
            if (answer.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  answer,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

List<_FleetSummaryInfo> _buildFleetSummaryEntries(
  List<FleetVehicleModel> vehicles,
) {
  final total = vehicles.length;
  final recent =
      vehicles
          .where((v) => v.year != null && v.year! >= DateTime.now().year - 5)
          .length;
  final legacy =
      vehicles
          .where((v) => v.year != null && v.year! < DateTime.now().year - 8)
          .length;
  final highUsage = vehicles.where((v) => v.odometer >= 100000).length;
  final withModel =
      vehicles.where((v) => (v.model ?? '').trim().isNotEmpty).length;

  return [
    _FleetSummaryInfo(
      key: 'all',
      label: 'Total',
      value: total.toString(),
      color: Colors.blueAccent,
      icon: Icons.directions_car_filled,
    ),
    _FleetSummaryInfo(
      key: 'recent',
      label: 'Recentes',
      value: recent.toString(),
      color: Colors.greenAccent,
      icon: Icons.fiber_new,
    ),
    _FleetSummaryInfo(
      key: 'legacy',
      label: 'Antigos',
      value: legacy.toString(),
      color: Colors.orangeAccent,
      icon: Icons.history_toggle_off,
    ),
    _FleetSummaryInfo(
      key: 'usage',
      label: 'Alto uso',
      value: highUsage.toString(),
      color: Colors.redAccent,
      icon: Icons.speed,
    ),
    _FleetSummaryInfo(
      key: 'model',
      label: 'Com modelo',
      value: withModel.toString(),
      color: Colors.purpleAccent,
      icon: Icons.directions_car_outlined,
    ),
  ];
}

class _FleetSummaryRow extends StatelessWidget {
  const _FleetSummaryRow({
    required this.entries,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<_FleetSummaryInfo> entries;
  final String selectedKey;
  final void Function(String key) onSelect;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final entry = entries[index];
          final isSelected = selectedKey == entry.key;
          final baseColor = entry.color;
          final background =
              isSelected
                  ? Color.lerp(baseColor, Colors.black, 0.5)!
                  : Colors.white.withValues(alpha: 0.04);
          final borderColor =
              isSelected
                  ? baseColor.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.05);
          return SizedBox(
            width: 150,
            child: GestureDetector(
              onTap: () => onSelect(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        entry.icon,
                        color: Color.lerp(baseColor, Colors.white, 0.3),
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FleetSummaryInfo {
  const _FleetSummaryInfo({
    required this.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String key;
  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _FleetSearchField extends StatelessWidget {
  const _FleetSearchField({required this.controller});

  final FleetController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasText = controller.search.value.isNotEmpty;
      return TextField(
        controller: controller.searchController,
        onChanged: (value) => controller.setSearch(value.toUpperCase()),
        style: const TextStyle(color: Colors.white),
        textCapitalization: TextCapitalization.characters,
        inputFormatters: const [UpperCaseTextFormatter()],
        decoration: InputDecoration(
          labelText: 'Buscar por placa ou modelo',
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              hasText
                  ? IconButton(
                    tooltip: 'Limpar busca',
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearSearch,
                  )
                  : null,
        ),
      );
    });
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.controller});

  final FleetController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.sort.value,
          dropdownColor: context.themeSurface,
          iconEnabledColor: Colors.white70,
          items: const [
            DropdownMenuItem(value: 'createdAt', child: Text('Criação')),
            DropdownMenuItem(value: 'odometer', child: Text('Odômetro')),
            DropdownMenuItem(value: 'plate', child: Text('Placa')),
          ],
          onChanged: (value) {
            if (value != null) controller.setSort(value);
          },
        ),
      ),
    );
  }
}

class _FleetEmptyState extends StatelessWidget {
  const _FleetEmptyState({
    required this.hasAnyVehicles,
    required this.hasSearch,
    required this.onClearFilters,
    required this.onCreate,
  });

  final bool hasAnyVehicles;
  final bool hasSearch;
  final VoidCallback onClearFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final title =
        hasAnyVehicles
            ? 'Nenhum veículo para os filtros atuais'
            : 'Você ainda não cadastrou veículos';
    final subtitle =
        hasAnyVehicles
            ? 'Ajuste os filtros ou limpe-os para visualizar outros veículos.'
            : 'Use o botão abaixo para adicionar um veículo à frota.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car_filled,
            size: 72,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          if (hasAnyVehicles)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar veículo'),
          ),
        ],
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  const _FleetCard({
    required this.vehicle,
    required this.controller,
    required this.onTap,
    required this.onEdit,
    required this.onHistory,
  });

  final FleetVehicleModel vehicle;
  final FleetController controller;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('pt_BR');
    final odometer = formatter.format(vehicle.odometer);
    final year = vehicle.year?.toString() ?? '—';
    final model =
        (vehicle.model ?? '').trim().isEmpty
            ? 'Modelo não informado'
            : vehicle.model!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        gradient: LinearGradient(
          colors: [
            Color.lerp(context.themeSurface, Colors.white, 0.04)!,
            context.themeSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PlateBadge(plate: vehicle.plate),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ano: $year • Odômetro: $odometer km',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white70),
                onPressed: onTap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.assignment_ind_outlined,
                text:
                    (vehicle.model ?? '').trim().isNotEmpty
                        ? 'Modelo definido'
                        : 'Sem modelo',
              ),
              _InfoChip(icon: Icons.speed, text: '$odometer km'),
              _InfoChip(icon: Icons.calendar_today_outlined, text: 'Ano $year'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(
                    Icons.history,
                    color: Colors.white70,
                    size: 18,
                  ),
                  label: const Text('Histórico'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          plate.trim().toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.redAccent : Colors.white70,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}


