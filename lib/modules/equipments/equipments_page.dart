import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/theme_extensions.dart';
import 'package:air_sync/application/utils/formatters/btus_input_formatter.dart';
import 'package:air_sync/application/utils/pdf/equipment_report_pdf.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:air_sync/modules/locations/locations_bindings.dart';
import 'package:air_sync/modules/locations/locations_page.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import 'equipment_history_bindings.dart';
import 'equipment_history_page.dart';
import 'equipments_controller.dart';

class EquipmentsPage extends GetView<EquipmentsController> {
  const EquipmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.themeDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Equipamentos',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.themeGreen,
        onPressed: () => _openCreateDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (controller.items.isEmpty) {
          return const Center(
            child: Text(
              'Sem equipamentos',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder:
              (_, index) =>
                  _buildEquipmentTile(context, controller.items[index]),
        );
      }),
    );
  }

  Widget _buildEquipmentTile(BuildContext context, EquipmentModel equipment) {
    final roomName = (equipment.room ?? '').trim();
    final locationLabel = controller.locationNames[equipment.locationId];
    final titleText =
        roomName.isNotEmpty
            ? 'Cômodo: $roomName'
            : 'Local: ${locationLabel ?? equipment.locationId}';
    final subtitleParts = <String?>[
      equipment.brand,
      equipment.model,
      equipment.type,
      equipment.serial,
      equipment.btus != null ? '${equipment.btus} BTUs' : null,
    ]..removeWhere((value) => (value ?? '').isEmpty);

    return ListTile(
      title: Text(titleText, style: const TextStyle(color: Colors.white)),
      subtitle:
          subtitleParts.isEmpty
              ? null
              : Text(
                subtitleParts.join(' • '),
                style: const TextStyle(color: Colors.white70),
              ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white70),
            tooltip: 'Histórico',
            onPressed: () => _openHistory(equipment),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            tooltip: 'Editar',
            onPressed: () => _openEditDialog(context, equipment),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onSelected: (value) {
              if (value == 'move') {
                _openMoveDialog(context, equipment);
              } else if (value == 'replace') {
                _openReplaceDialog(context, equipment);
              } else if (value == 'report') {
                _openReportDialog(context, equipment);
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(
                    value: 'move',
                    child: Text('Mover equipamento'),
                  ),
                  PopupMenuItem(
                    value: 'replace',
                    child: Text('Substituir equipamento'),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    child: Text('Relatório (PDF)'),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Excluir',
            onPressed: () => _confirmDelete(context, equipment.id),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.themeDark,
        title: const Text(
          'Excluir equipamento',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja excluir?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await controller.delete(id);
              Get.back();
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    EquipmentModel equipment,
  ) async {
    final brandCtrl = TextEditingController(text: equipment.brand ?? '');
    final modelCtrl = TextEditingController(text: equipment.model ?? '');
    final typeCtrl = TextEditingController(text: equipment.type ?? '');
    final btusCtrl = TextEditingController(
      text: equipment.btus?.toString() ?? '',
    );
    final roomCtrl = TextEditingController(text: equipment.room ?? '');
    final serialCtrl = TextEditingController(text: equipment.serial ?? '');
    final notesCtrl = TextEditingController(text: equipment.notes ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom + 30;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: bottomInset,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editar equipamento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Campos marcados com * são obrigatórios.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brandCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Marca *'),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe a marca'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: modelCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Modelo *'),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe o modelo'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: typeCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tipo (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: btusCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [BtusInputFormatter()],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'BTUs *'),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe os BTUs'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: roomCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Cômodo/ambiente *',
                    ),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe o cômodo/ambiente'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: serialCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Serial (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
                        final btus = _parseBtus(btusCtrl.text);
                        await controller.updateEquipment(
                          id: equipment.id,
                          brand: brandCtrl.text.trim(),
                          model: modelCtrl.text.trim(),
                          type:
                              typeCtrl.text.trim().isEmpty
                                  ? null
                                  : typeCtrl.text.trim(),
                          btus: btus,
                          room: roomCtrl.text.trim(),
                          serial:
                              serialCtrl.text.trim().isEmpty
                                  ? null
                                  : serialCtrl.text.trim(),
                          notes:
                              notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                        );
                        Navigator.of(sheetCtx).pop();
                      },
                      child: Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themeGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    brandCtrl.dispose();
    modelCtrl.dispose();
    typeCtrl.dispose();
    btusCtrl.dispose();
    roomCtrl.dispose();
    serialCtrl.dispose();
    notesCtrl.dispose();
  }

  void _openHistory(EquipmentModel equipment) {
    Get.to(
      () => const EquipmentHistoryPage(),
      arguments: {'id': equipment.id, 'equipment': equipment},
      binding: EquipmentHistoryBindings(),
    );
  }

  Future<void> _openMoveDialog(
    BuildContext context,
    EquipmentModel equipment,
  ) async {
    final locService = Get.find<LocationsService>();
    final initialLocations = await locService.listByClient(
      controller.client.id,
    );

    final locations = initialLocations.obs;
    final selectedLocationId = RxnString(equipment.locationId);
    final formKey = GlobalKey<FormState>();
    final roomCtrl = TextEditingController(text: equipment.room ?? '');
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom + 30;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: bottomInset,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: Obx(() {
              final hasLocations = locations.isNotEmpty;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mover equipamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Campos marcados com * são obrigatórios.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (hasLocations)
                      DropdownButtonFormField<String>(
                        value: selectedLocationId.value,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: context.themeDark,
                        items:
                            locations
                                .map(
                                  (location) => DropdownMenuItem(
                                    value: location.id,
                                    child: Text(
                                      _locationDisplay(location),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => selectedLocationId.value = value,
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Selecione um local'
                                    : null,
                        decoration: const InputDecoration(
                          labelText: 'Novo local *',
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nenhum endereço cadastrado para este cliente.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Get.to(
                                () => const LocationsPage(),
                                binding: LocationsBindings(),
                                arguments: controller.client,
                              );
                              final refreshed = await locService.listByClient(
                                controller.client.id,
                              );
                              locations.assignAll(refreshed);
                              selectedLocationId.value =
                                  locations.isNotEmpty
                                      ? locations.first.id
                                      : null;
                            },
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('Cadastrar endereço'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: roomCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Novo cômodo *',
                      ),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe o novo cômodo'
                                  : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.themeGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed:
                            selectedLocationId.value == null
                                ? null
                                : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  await controller.move(
                                    id: equipment.id,
                                    toLocationId: selectedLocationId.value!,
                                    toRoom: roomCtrl.text.trim(),
                                    toClientId: controller.client.id,
                                    notes:
                                        notesCtrl.text.trim().isEmpty
                                            ? null
                                            : notesCtrl.text.trim(),
                                  );
                                  Navigator.of(sheetCtx).pop();
                                },
                        child: Text(
                          'Mover',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.themeGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );

    roomCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final locService = Get.find<LocationsService>();
    final initialLocations = await locService.listByClient(
      controller.client.id,
    );

    final locations = initialLocations.obs;
    final selectedLocationId = RxnString(
      initialLocations.isNotEmpty ? initialLocations.first.id : null,
    );
    final formKey = GlobalKey<FormState>();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final btusCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom + 30;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: bottomInset,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: Obx(() {
              final hasLocations = locations.isNotEmpty;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo equipamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Campos marcados com * são obrigatórios.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (hasLocations)
                      DropdownButtonFormField<String>(
                        value: selectedLocationId.value,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: context.themeDark,
                        items:
                            locations
                                .map(
                                  (location) => DropdownMenuItem(
                                    value: location.id,
                                    child: Text(
                                      _locationDisplay(location),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => selectedLocationId.value = value,
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? 'Selecione um local'
                                    : null,
                        decoration: const InputDecoration(labelText: 'Local *'),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nenhum endereço cadastrado para este cliente.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Get.to(
                                () => const LocationsPage(),
                                binding: LocationsBindings(),
                                arguments: controller.client,
                              );
                              final refreshed = await locService.listByClient(
                                controller.client.id,
                              );
                              locations.assignAll(refreshed);
                              selectedLocationId.value =
                                  locations.isNotEmpty
                                      ? locations.first.id
                                      : null;
                            },
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('Cadastrar endereço'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: brandCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Marca *'),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe a marca'
                                  : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: modelCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Modelo *'),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe o modelo'
                                  : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: typeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tipo (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: btusCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [BtusInputFormatter()],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'BTUs *'),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe os BTUs'
                                  : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: roomCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Cômodo/ambiente *',
                      ),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Informe o cômodo/ambiente'
                                  : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: serialCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Serial (opcional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
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
                              onPressed:
                                  selectedLocationId.value == null
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        final btus = _parseBtus(btusCtrl.text);
                                        await controller.create(
                                          locationId: selectedLocationId.value!,
                                          brand: brandCtrl.text.trim(),
                                          model: modelCtrl.text.trim(),
                                          type:
                                              typeCtrl.text.trim().isEmpty
                                                  ? null
                                                  : typeCtrl.text.trim(),
                                          btus: btus,
                                          room: roomCtrl.text.trim(),
                                          serial:
                                              serialCtrl.text.trim().isEmpty
                                                  ? null
                                                  : serialCtrl.text.trim(),
                                          notes:
                                              notesCtrl.text.trim().isEmpty
                                                  ? null
                                                  : notesCtrl.text.trim(),
                                        );
                                        Navigator.of(sheetCtx).pop();
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
              );
            }),
          ),
        );
      },
    );

    brandCtrl.dispose();
    modelCtrl.dispose();
    typeCtrl.dispose();
    btusCtrl.dispose();
    roomCtrl.dispose();
    serialCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _openReplaceDialog(
    BuildContext context,
    EquipmentModel equipment,
  ) async {
    final brandCtrl = TextEditingController(text: equipment.brand ?? '');
    final modelCtrl = TextEditingController(text: equipment.model ?? '');
    final typeCtrl = TextEditingController(text: equipment.type ?? '');
    final btusCtrl = TextEditingController(
      text: equipment.btus?.toString() ?? '',
    );
    final roomCtrl = TextEditingController(text: equipment.room ?? '');
    final serialCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom + 30;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: bottomInset,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Substituir equipamento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Campos marcados com * são obrigatórios.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: brandCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Marca *'),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe a marca'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: modelCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Modelo *'),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe o modelo'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: typeCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tipo (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: btusCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [BtusInputFormatter()],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'BTUs *'),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe os BTUs'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: roomCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Cômodo/ambiente *',
                    ),
                    validator:
                        (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe o cômodo/ambiente'
                                : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: serialCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Serial (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
                        final btus = _parseBtus(btusCtrl.text);
                        await controller.replace(
                          id: equipment.id,
                          newEquipment: {
                            'brand': brandCtrl.text.trim(),
                            'model': modelCtrl.text.trim(),
                            'type':
                                typeCtrl.text.trim().isEmpty
                                    ? null
                                    : typeCtrl.text.trim(),
                            'btus': btus,
                            'room': roomCtrl.text.trim(),
                            'serial':
                                serialCtrl.text.trim().isEmpty
                                    ? null
                                    : serialCtrl.text.trim(),
                          },
                          notes:
                              notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                        );
                        Navigator.of(sheetCtx).pop();
                      },
                      child: Text(
                        'Substituir',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themeGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    brandCtrl.dispose();
    modelCtrl.dispose();
    typeCtrl.dispose();
    btusCtrl.dispose();
    roomCtrl.dispose();
    serialCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _openReportDialog(
    BuildContext context,
    EquipmentModel equipment,
  ) async {
    final recipientCtrl = TextEditingController();
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: context.themeDark,
        title: const Text(
          'Relatório (PDF)',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: recipientCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Destinatário (opcional)',
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              try {
                final historyRaw = await Get.find<EquipmentsService>()
                    .listHistory(equipment.id);
                final history =
                    historyRaw
                        .map(
                          (entry) => MaintenanceModel.fromMap(
                            Map<String, dynamic>.from(entry),
                          ),
                        )
                        .toList();
                final user = Get.find<AuthServiceApplication>().user.value;
                final bytes = await buildEquipmentReportPdf(
                  equipment: equipment,
                  history: history,
                  appName: 'AirSync',
                  clientName: controller.client.name,
                  locationLabel: controller.locationNames[equipment.locationId],
                  companyName: user?.name,
                  companyDocument: user?.cpfOrCnpj,
                  companyEmail: user?.email,
                  companyPhone: user?.phone,
                );
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'equipamento_${equipment.id}.pdf',
                );
              } catch (_) {
                Get.snackbar(
                  'Erro',
                  'Não foi possível gerar o PDF do equipamento.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent,
                  colorText: Colors.white,
                );
              } finally {
                Get.back();
              }
            },
            child: const Text('Gerar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    recipientCtrl.dispose();
  }

  String _locationDisplay(LocationModel location) {
    final parts = <String>[];
    if (location.label.isNotEmpty) {
      parts.add(location.label);
    }
    final address = location.addressLine;
    if (address.isNotEmpty) {
      parts.add(address);
    }
    final cityState = location.cityState;
    if (cityState.isNotEmpty) {
      parts.add(cityState);
    }
    return parts.join(' • ');
  }

  int? _parseBtus(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return null;
    }
    return int.tryParse(digits);
  }
}
