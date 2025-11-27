import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DraftBasicsResult {
  DraftBasicsResult({
    required this.clientId,
    required this.locationId,
    this.equipmentId,
  });

  final String clientId;
  final String locationId;
  final String? equipmentId;
}

Future<DraftBasicsResult?> showDraftBasicsSheet({
  required BuildContext context,
  required OrderModel order,
}) {
  return showModalBottomSheet<DraftBasicsResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).dialogTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (_) => _DraftBasicsSheet(
          order: order,
          clientService: Get.find<ClientService>(),
          locationsService: Get.find<LocationsService>(),
          equipmentsService: Get.find<EquipmentsService>(),
        ),
  );
}

class _DraftBasicsSheet extends StatelessWidget {
  const _DraftBasicsSheet({
    required this.order,
    required this.clientService,
    required this.locationsService,
    required this.equipmentsService,
  });

  final OrderModel order;
  final ClientService clientService;
  final LocationsService locationsService;
  final EquipmentsService equipmentsService;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GetBuilder<_DraftBasicsController>(
        init: _DraftBasicsController(
          clientService: clientService,
          locationsService: locationsService,
          equipmentsService: equipmentsService,
          initialClientId: order.clientId,
          initialLocationId: order.locationId,
          initialEquipmentId: order.equipmentId,
        ),
        builder: (controller) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Editar dados do rascunho',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => _DropdownSection<String>(
                      label: 'Cliente',
                      isLoading: controller.loadingClients.value,
                      value: controller.selectedClientId.value,
                      items: controller.clients
                          .map(
                            (client) => DropdownMenuItem<String>(
                              value: client.id,
                              child: Text(client.name),
                            ),
                          )
                          .toList(),
                      onChanged: controller.loadingClients.value
                          ? null
                          : controller.selectClient,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _DropdownSection<String>(
                      label: 'Endereço / Local',
                      isLoading: controller.loadingLocations.value,
                      value: controller.selectedLocationId.value,
                      items: controller.locations
                          .map(
                            (location) => DropdownMenuItem<String>(
                              value: location.id,
                              child: Text(_locationLabel(location)),
                            ),
                          )
                          .toList(),
                      onChanged: controller.loadingLocations.value
                          ? null
                          : controller.selectLocation,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => _DropdownSection<String>(
                      label: 'Equipamento',
                      isLoading: controller.loadingEquipments.value,
                      value: controller.selectedEquipmentId.value,
                      allowEmpty: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Sem equipamento'),
                        ),
                        ...controller.equipments.map(
                          (equipment) => DropdownMenuItem<String>(
                            value: equipment.id,
                            child: Text(_equipmentLabel(equipment)),
                          ),
                        ),
                      ],
                      onChanged: controller.loadingEquipments.value
                          ? null
                          : controller.selectEquipment,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => ElevatedButton(
                      onPressed:
                          controller.canSubmit
                              ? () => Get.back(result: controller.buildResult())
                              : null,
                      child: const Text('Aplicar alterações'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DropdownSection<T> extends StatelessWidget {
  const _DropdownSection({
    required this.label,
    required this.isLoading,
    required this.value,
    required this.items,
    required this.onChanged,
    this.allowEmpty = false,
  });

  final String label;
  final bool isLoading;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool allowEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        isLoading
            ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
            : DropdownButtonFormField<T>(
              value: allowEmpty ? value : value,
              items: items,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
      ],
    );
  }
}

class _DraftBasicsController extends GetxController {
  _DraftBasicsController({
    required this.clientService,
    required this.locationsService,
    required this.equipmentsService,
    required this.initialClientId,
    required this.initialLocationId,
    required this.initialEquipmentId,
  });

  final ClientService clientService;
  final LocationsService locationsService;
  final EquipmentsService equipmentsService;

  final String initialClientId;
  final String initialLocationId;
  final String? initialEquipmentId;

  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxList<LocationModel> locations = <LocationModel>[].obs;
  final RxList<EquipmentModel> equipments = <EquipmentModel>[].obs;

  final RxBool loadingClients = true.obs;
  final RxBool loadingLocations = false.obs;
  final RxBool loadingEquipments = false.obs;

  final RxnString selectedClientId = RxnString();
  final RxnString selectedLocationId = RxnString();
  final RxnString selectedEquipmentId = RxnString();

  bool _initialClientApplied = false;
  bool _initialLocationApplied = false;
  bool _initialEquipmentApplied = false;

  bool get canSubmit =>
      (selectedClientId.value ?? '').isNotEmpty &&
      (selectedLocationId.value ?? '').isNotEmpty;

  DraftBasicsResult buildResult() {
    return DraftBasicsResult(
      clientId: selectedClientId.value!,
      locationId: selectedLocationId.value!,
      equipmentId:
          (selectedEquipmentId.value ?? '').isEmpty
              ? null
              : selectedEquipmentId.value,
    );
  }

  @override
  void onInit() {
    super.onInit();
    _loadClients();
  }

  Future<void> _loadClients() async {
    loadingClients.value = true;
    try {
      final data = await clientService.list(limit: 200);
      clients.assignAll(data);
      if (!_initialClientApplied && initialClientId.isNotEmpty) {
        if (!clients.any((c) => c.id == initialClientId)) {
          try {
            final fetched = await clientService.getById(initialClientId);
            clients.insert(0, fetched);
          } catch (_) {}
        }
        selectedClientId.value = initialClientId;
        _initialClientApplied = true;
      } else if (selectedClientId.value == null && clients.isNotEmpty) {
        selectedClientId.value = clients.first.id;
      }
    } finally {
      loadingClients.value = false;
    }
    final clientId = selectedClientId.value;
    if (clientId != null && clientId.isNotEmpty) {
      await _loadLocations(clientId);
    }
  }

  Future<void> _loadLocations(String clientId) async {
    loadingLocations.value = true;
    try {
      final data = await locationsService.listByClient(clientId);
      locations.assignAll(data);
      if (!_initialLocationApplied && initialLocationId.isNotEmpty) {
        if (locations.any((l) => l.id == initialLocationId)) {
          selectedLocationId.value = initialLocationId;
        }
        _initialLocationApplied = true;
      }
      selectedLocationId.value ??= locations.isNotEmpty ? locations.first.id : null;
    } finally {
      loadingLocations.value = false;
    }
    final locId = selectedLocationId.value;
    if (locId != null && locId.isNotEmpty) {
      await _loadEquipments(clientId: clientId, locationId: locId);
    } else {
      equipments.clear();
      selectedEquipmentId.value = null;
    }
  }

  Future<void> _loadEquipments({
    required String clientId,
    required String locationId,
  }) async {
    loadingEquipments.value = true;
    try {
      final data = await equipmentsService.listBy(
        clientId,
        locationId: locationId,
      );
      equipments.assignAll(data);
      if (!_initialEquipmentApplied && (initialEquipmentId ?? '').isNotEmpty) {
        if (equipments.any((e) => e.id == initialEquipmentId)) {
          selectedEquipmentId.value = initialEquipmentId;
        }
        _initialEquipmentApplied = true;
      }
      selectedEquipmentId.value ??=
          equipments.isNotEmpty ? equipments.first.id : '';
    } finally {
      loadingEquipments.value = false;
    }
  }

  Future<void> selectClient(String? id) async {
    if (id == null || id.isEmpty) return;
    selectedClientId.value = id;
    _initialLocationApplied = true;
    _initialEquipmentApplied = true;
    selectedLocationId.value = null;
    selectedEquipmentId.value = null;
    await _loadLocations(id);
  }

  Future<void> selectLocation(String? id) async {
    if (id == null || id.isEmpty) {
      selectedLocationId.value = null;
      equipments.clear();
      selectedEquipmentId.value = null;
      return;
    }
    selectedLocationId.value = id;
    _initialEquipmentApplied = true;
    final clientId = selectedClientId.value;
    if (clientId != null && clientId.isNotEmpty) {
      await _loadEquipments(clientId: clientId, locationId: id);
    }
  }

  void selectEquipment(String? id) {
    selectedEquipmentId.value = id ?? '';
  }
}

String _locationLabel(LocationModel model) {
  final parts = <String>[];
  if (model.label.trim().isNotEmpty) parts.add(model.label.trim());
  if (model.addressLine.trim().isNotEmpty) parts.add(model.addressLine.trim());
  if (model.cityState.trim().isNotEmpty) parts.add(model.cityState.trim());
  return parts.isEmpty ? 'Local ${model.id}' : parts.join(' - ');
}

String _equipmentLabel(EquipmentModel equipment) {
  final parts = <String>[];
  if ((equipment.room ?? '').trim().isNotEmpty) {
    parts.add(equipment.room!.trim());
  }
  if ((equipment.brand ?? '').trim().isNotEmpty) {
    parts.add(equipment.brand!.trim());
  }
  if ((equipment.model ?? '').trim().isNotEmpty) {
    parts.add(equipment.model!.trim());
  }
  if ((equipment.type ?? '').trim().isNotEmpty) {
    parts.add(equipment.type!.trim());
  }
  return parts.isEmpty ? 'Equipamento ${equipment.id}' : parts.join(' - ');
}
