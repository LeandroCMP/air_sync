import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/modules/fleet/fleet_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:air_sync/application/core/form_validator.dart';
import 'package:get/get.dart';
import 'fleet_controller.dart';

class FleetPage extends GetView<FleetController> {
  const FleetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Frota', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openVehicleForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                onChanged: (v) => controller.setSearch(v),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por placa/modelo',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  const Text(
                    'Ordenar por:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: controller.sort.value,
                    dropdownColor: context.themeDark,
                    items: const [
                      DropdownMenuItem(
                        value: 'createdAt',
                        child: Text('Criação'),
                      ),
                      DropdownMenuItem(
                        value: 'odometer',
                        child: Text('Odômetro'),
                      ),
                      DropdownMenuItem(value: 'plate', child: Text('Placa')),
                    ],
                    onChanged: (v) => controller.setSort(v ?? 'createdAt'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Alternar ordem',
                    onPressed: () => controller.toggleOrder(),
                    icon: Obx(
                      () => Icon(
                        controller.order.value == 'asc'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isLoading.value)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child:
                  controller.items.isEmpty
                      ? const Center(
                        child: Text(
                          'Sem veículos',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : ListView.separated(
                        itemCount: controller.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final v = controller.items[i];
                          return ListTile(
                            title: Text(
                              v.plate,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Modelo: ${v.model ?? '-'} • Ano: ${v.year?.toString() ?? '-'} • Odômetro: ${v.odometer}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.more_horiz),
                              onPressed: () => _openVehicleActions(context, v),
                            ),
                            onLongPress:
                                () => _openVehicleForm(context, vehicle: v),
                          );
                        },
                      ),
            ),
          ],
        );
      }),
    );
  }

  void _openVehicleActions(BuildContext context, dynamic v) {
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
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Check'),
                onTap: () {
                  Get.back();
                  _openCheckDialog(context, v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_gas_station_outlined),
                title: const Text('Abastecimento'),
                onTap: () {
                  Get.back();
                  _openFuelDialog(context, v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: const Text('Manutenção'),
                onTap: () {
                  Get.back();
                  _openMaintenanceDialog(context, v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Histórico'),
                onTap: () {
                  Get.back();
                  _openHistory(context, v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  Get.back();
                  _openVehicleForm(context, vehicle: v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Excluir'),
                onTap: () async {
                  Get.back();
                  final ok = await Get.dialog(
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
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text(
                            'Excluir',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await Get.find<FleetController>().deleteVehicle(v.id);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openCheckDialog_legacy(BuildContext context, dynamic v) {
    final odoCtrl = TextEditingController(text: v.odometer.toString());
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int fuelLevel = 50;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nível de combustível',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              '$fuelLevel%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Slider(
                          value: fuelLevel.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '$fuelLevel%',
                          onChanged:
                              (vVal) =>
                                  setState(() => fuelLevel = vVal.round()),
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
                                    if (!formKey.currentState!.validate())
                                      return;
                                    final odo =
                                        int.tryParse(odoCtrl.text.trim()) ?? 0;
                                    if (odo < v.odometer) {
                                      Get.snackbar(
                                        'Frota',
                                        'Odômetro não pode regredir',
                                      );
                                      return;
                                    }
                                    await controller.doCheck(
                                      v,
                                      odometer: odo,
                                      fuelLevel: fuelLevel,
                                      notes:
                                          notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                    );
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
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
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
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
          ),
    );
  }

  void _openCheckDialog(BuildContext context, dynamic v) {
    final odoCtrl = TextEditingController(text: v.odometer.toString());
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int fuelLevel = 50;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nível de combustível',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              '$fuelLevel%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Slider(
                          value: fuelLevel.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '$fuelLevel%',
                          onChanged:
                              (vVal) =>
                                  setState(() => fuelLevel = vVal.round()),
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
                                    if (!formKey.currentState!.validate())
                                      return;
                                    final odo =
                                        int.tryParse(odoCtrl.text.trim()) ?? 0;
                                    if (odo < v.odometer) {
                                      Get.snackbar(
                                        'Frota',
                                        'Odômetro não pode regredir',
                                      );
                                      return;
                                    }
                                    await controller.doCheck(
                                      v,
                                      odometer: odo,
                                      fuelLevel: fuelLevel,
                                      notes:
                                          notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                    );
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
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
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
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
          ),
    );
  }

  void _openFuelDialog(BuildContext context, dynamic v) {
    final odoCtrl = TextEditingController(text: v.odometer.toString());
    final litersCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    String fuelType = 'gasoline';

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Padding(
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
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                validator:
                                    (v) => FormValidators.validateNumber(
                                      v,
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
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                validator:
                                    (v) => FormValidators.validateNumber(
                                      v,
                                      fieldName: 'Preço total',
                                      positive: true,
                                    ),
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Preço total',
                                  prefixText: 'R\$ ',
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: fuelType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de combustível',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: context.themeDark,
                          items: const [
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
                            DropdownMenuItem(value: 'gnv', child: Text('GNV')),
                            DropdownMenuItem(
                              value: 'electric',
                              child: Text('Elétrico'),
                            ),
                          ],
                          onChanged:
                              (vVal) =>
                                  setState(() => fuelType = vVal ?? 'gasoline'),
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'Selecione o tipo de combustível'
                                      : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: odoCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                                    if (!formKey.currentState!.validate())
                                      return;
                                    final liters =
                                        double.tryParse(
                                          litersCtrl.text.trim().replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        ) ??
                                        0;
                                    final price =
                                        double.tryParse(
                                          priceCtrl.text.trim().replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        ) ??
                                        0;
                                    final odo =
                                        int.tryParse(odoCtrl.text.trim()) ?? 0;
                                    if (liters <= 0 || price <= 0) return;
                                    if (odo < v.odometer) {
                                      Get.snackbar(
                                        'Frota',
                                        'Odômetro não pode regredir',
                                      );
                                      return;
                                    }
                                    await controller.doFuel(
                                      v,
                                      liters: liters,
                                      price: price,
                                      fuelType: fuelType,
                                      odometer: odo,
                                    );
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
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
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
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
          ),
    );
  }

  void _openMaintenanceDialog(BuildContext context, dynamic v) {
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '0');
    final odoCtrl = TextEditingController(text: v.odometer.toString());
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      useRootNavigator: true,
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
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
              top: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registrar Manutenção',
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
                        (v) => FormValidators.validateNotEmpty(
                          v,
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator:
                              (v) => FormValidators.validateOptionalNumber(
                                v,
                                fieldName: 'Custo',
                                positive: true,
                              ),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Custo (opcional)',
                            prefixText: 'R\$ ',
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
                              final desc = descCtrl.text.trim();
                              final cost =
                                  costCtrl.text.trim().isEmpty
                                      ? null
                                      : double.tryParse(
                                        costCtrl.text.trim().replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      );
                              final odo =
                                  int.tryParse(odoCtrl.text.trim()) ?? 0;
                              if (odo < v.odometer) {
                                Get.snackbar(
                                  'Frota',
                                  'Odômetro não pode regredir',
                                );
                                return;
                              }
                              await controller.doMaintenance(
                                v,
                                description: desc,
                                cost: cost,
                                odometer: odo,
                              );
                              Navigator.of(context, rootNavigator: true).pop();
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

  void _openVehicleForm(BuildContext context, {dynamic vehicle}) {
    final isEdit = vehicle != null;
    final plateCtrl = TextEditingController(
      text: isEdit ? vehicle.plate.toString() : '',
    );
    final modelCtrl = TextEditingController(
      text: isEdit ? (vehicle.model?.toString() ?? '') : '',
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
                            child: Text(
                              'Salvar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.themeGray,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.themeGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final plate = plateCtrl.text.trim();
                              final odometer =
                                  int.tryParse(odoCtrl.text.trim()) ?? 0;
                              final year =
                                  yearCtrl.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(yearCtrl.text.trim());
                              final model =
                                  modelCtrl.text.trim().isEmpty
                                      ? null
                                      : modelCtrl.text.trim();
                              final ctrl = Get.find<FleetController>();
                              if (isEdit) {
                                if (isEdit) {
                                  await ctrl.updateVehicle(
                                    vehicle.id,
                                    plate: plate,
                                    model: model,
                                    year: year,
                                    odometer: odometer,
                                  );
                                } else {
                                  await ctrl.createVehicle(
                                    plate: plate,
                                    model: model,
                                    year: year,
                                    odometer: odometer,
                                  );
                                }
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                            },
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

  void _openHistory(BuildContext context, dynamic v) {
    Get.to(() => FleetHistoryPage(vehicleId: v.id, title: v.plate));
  }
}
