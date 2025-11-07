import 'dart:async';

import 'package:air_sync/application/core/errors/inventory_failure.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/models/order_draft_model.dart';
import 'package:air_sync/modules/orders/orders_controller.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/orders/order_label_service.dart';
import 'package:air_sync/services/orders/order_draft_storage.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'order_create_result.dart';

class OrderCreateController extends GetxController
    with LoaderMixin, MessagesMixin {
  OrderCreateController({
    required OrdersService ordersService,
    required ClientService clientService,
    required LocationsService locationsService,
    required EquipmentsService equipmentsService,
    required InventoryService inventoryService,
    required OrderLabelService labelService,
    required UsersService usersService,
    required OrderDraftStorage draftStorage,
    OrderDraftModel? initialDraft,
  }) : _ordersService = ordersService,
       _clientService = clientService,
       _locationsService = locationsService,
       _equipmentsService = equipmentsService,
       _inventoryService = inventoryService,
       _labelService = labelService,
       _usersService = usersService,
       _draftStorage = draftStorage,
       _initialDraft = initialDraft {
    _setEditingDraft(initialDraft);
  }

  final OrdersService _ordersService;
  final ClientService _clientService;
  final LocationsService _locationsService;
  final EquipmentsService _equipmentsService;
  final InventoryService _inventoryService;
  final OrderLabelService _labelService;
  final UsersService _usersService;
  final OrderDraftStorage _draftStorage;
  final OrderDraftModel? _initialDraft;
  OrderDraftModel? _editingDraft;
  bool _draftApplied = false;

  final RxBool _hasDraft = false.obs;

  bool get isEditingDraft => _hasDraft.value;

  void _setEditingDraft(OrderDraftModel? draft) {
    _editingDraft = draft;
    void updateFlag() => _hasDraft.value = draft != null;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      updateFlag();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => updateFlag());
    }
  }

  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final isInventoryLoading = false.obs;
  final RxnString inventoryError = RxnString();

  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxnString selectedClientId = RxnString();

  final RxList<LocationModel> locations = <LocationModel>[].obs;
  final RxnString selectedLocationId = RxnString();

  final RxList<EquipmentModel> equipments = <EquipmentModel>[].obs;
  final RxnString selectedEquipmentId = RxnString();

  final RxList<InventoryItemModel> inventoryItems = <InventoryItemModel>[].obs;

  final Rxn<DateTime> scheduledAt = Rxn<DateTime>();

  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();

  final RxList<String> checklist = <String>[].obs;
  final TextEditingController checklistCtrl = TextEditingController();

  final RxList<OrderMaterialDraft> materials = <OrderMaterialDraft>[].obs;
  final RxList<OrderBillingDraft> billingItems = <OrderBillingDraft>[].obs;
  final RxList<CollaboratorModel> technicians = <CollaboratorModel>[].obs;
  final RxList<String> selectedTechnicianIds = <String>[].obs;

  @override
  void onInit() {
    messageListener(message);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await _loadClients();
    await _loadInventoryItems();
    await _loadTechnicians();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _maybeApplyInitialDraft();
      });
    });
    if (billingItems.isEmpty) addBillingRow();
    super.onReady();
  }

  Future<void> _loadClients() async {
    try {
      final result = await _clientService.list(limit: 100);
      clients.assignAll(result);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Clientes',
          message: 'Falha ao carregar clientes.',
        ),
      );
    }
  }

  Future<void> _loadInventoryItems() async {
    try {
      isInventoryLoading(true);
      inventoryError.value = null;
      final items = await _inventoryService.listItems();
      final filtered =
          items.where((item) => item.active).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
      inventoryItems.assignAll(filtered);
    } on InventoryFailure catch (e) {
      inventoryError.value = e.message;
    } catch (_) {
      inventoryError.value = 'Nao foi possivel carregar os itens do estoque.';
    } finally {
      isInventoryLoading(false);
    }
  }

  Future<bool> ensureInventoryLoaded() async {
    if (inventoryItems.isNotEmpty) return true;
    await _loadInventoryItems();
    return inventoryItems.isNotEmpty;
  }

  Future<void> _loadTechnicians() async {
    try {
      final result = await _usersService.list();
      List<CollaboratorModel> sortByName(List<CollaboratorModel> src) =>
          src..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

      final techOnly = sortByName(
        result
            .where((tech) => tech.active && tech.role == CollaboratorRole.tech)
            .toList(),
      );

      if (techOnly.isNotEmpty) {
        technicians.assignAll(techOnly);
        return;
      }

      final activeFallback = sortByName(
        result.where((tech) => tech.active).toList(),
      );
      technicians.assignAll(activeFallback);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Tecnicos',
          message: 'Falha ao carregar tecnicos.',
        ),
      );
    }
  }

  Future<void> _maybeApplyInitialDraft() async {
    if (_initialDraft == null || _draftApplied) return;
    _draftApplied = true;
    await _applyDraft(_initialDraft!);
  }

  Future<void> _applyDraft(OrderDraftModel draft) async {
    await _waitFrame();
    _setEditingDraft(draft);
    final clientId = draft.clientId;
    if (clientId != null && clientId.isNotEmpty) {
      if (!clients.any((client) => client.id == clientId)) {
        try {
          final fetched = await _clientService.getById(clientId);
          clients.add(fetched);
        } catch (_) {}
      }
      await onClientSelected(clientId);
    }
    final locationId = draft.locationId;
    if (locationId != null && locationId.isNotEmpty) {
      await onLocationSelected(locationId);
    }
    if ((draft.equipmentId ?? '').isNotEmpty) {
      selectedEquipmentId.value = draft.equipmentId;
    }
    scheduledAt.value = draft.scheduledAt;
    _setControllerText(notesCtrl, draft.notes ?? '');
    if (draft.billingDiscount != 0) {
      final formatted = draft.billingDiscount.toStringAsFixed(
        draft.billingDiscount % 1 == 0 ? 0 : 2,
      );
      _setControllerText(discountCtrl, formatted);
    } else {
      _setControllerText(discountCtrl, '');
    }
    selectedTechnicianIds.assignAll(draft.technicianIds);
    checklist.assignAll(draft.checklist);

    materials.clear();
    if (draft.materials.isNotEmpty) {
      for (final data in draft.materials) {
        final entry = OrderMaterialDraft();
        entry.loadFromDraft(data);
        materials.add(entry);
      }
    }

    billingItems.clear();
    if (draft.billingItems.isEmpty) {
      addBillingRow();
    } else {
      for (final data in draft.billingItems) {
        final entry = OrderBillingDraft();
        entry.loadFromDraft(data);
        billingItems.add(entry);
      }
    }
  }

  void setTechnicians(List<String> ids) {
    selectedTechnicianIds
      ..clear()
      ..assignAll(ids.toSet());
  }

  void toggleTechnician(String id) {
    if (selectedTechnicianIds.contains(id)) {
      selectedTechnicianIds.remove(id);
    } else {
      selectedTechnicianIds.add(id);
    }
  }

  void removeTechnician(String id) => selectedTechnicianIds.remove(id);

  List<CollaboratorModel> get selectedTechnicians =>
      technicians
          .where((tech) => selectedTechnicianIds.contains(tech.id))
          .toList();

  Future<void> refreshInventory() => _loadInventoryItems();

  Future<void> onClientSelected(String? clientId) async {
    selectedClientId.value = clientId;
    selectedLocationId.value = null;
    selectedEquipmentId.value = null;
    locations.clear();
    equipments.clear();
    if (clientId == null) return;
    try {
      final data = await _locationsService.listByClient(clientId);
      locations.assignAll(data);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Enderecos',
          message: 'Falha ao carregar enderecos.',
        ),
      );
    }
  }

  Future<void> onLocationSelected(String? locationId) async {
    selectedLocationId.value = locationId;
    selectedEquipmentId.value = null;
    equipments.clear();
    final clientId = selectedClientId.value;
    if (clientId == null || locationId == null) return;
    try {
      final data = await _equipmentsService.listBy(
        clientId,
        locationId: locationId,
      );
      equipments.assignAll(data);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Equipamentos',
          message: 'Falha ao carregar equipamentos.',
        ),
      );
    }
  }

  void setEquipment(String? id) => selectedEquipmentId.value = id;

  void setScheduledAt(DateTime? dateTime) => scheduledAt.value = dateTime;

  void clearScheduledAt() => scheduledAt.value = null;

  void addChecklistItem() {
    final text = checklistCtrl.text.trim();
    if (text.isEmpty) return;
    checklist.add(text);
    checklistCtrl.clear();
  }

  void removeChecklistItem(int index) {
    if (index < 0 || index >= checklist.length) return;
    checklist.removeAt(index);
  }

  void addMaterialRow() => materials.add(OrderMaterialDraft());

  void removeMaterialRow(int index) {
    if (index < 0 || index >= materials.length) return;
    final entry = materials.removeAt(index);
    entry.dispose();
  }

  void setMaterialItem(int index, InventoryItemModel? item) {
    if (index < 0 || index >= materials.length) return;
    if (item == null) {
      materials[index].clearSelection();
      return;
    }
    materials[index].itemId.value = item.id;
    final description = item.description.trim();
    final sku = item.sku.trim();
    final preferredName =
        description.isNotEmpty ? description : (sku.isNotEmpty ? sku : item.id);
    materials[index].itemName.value = preferredName;
  }

  void addBillingRow() => billingItems.add(OrderBillingDraft());

  void removeBillingRow(int index) {
    if (index < 0 || index >= billingItems.length) return;
    final entry = billingItems.removeAt(index);
    entry.dispose();
  }

  Future<void> submit() async {
    final clientId = selectedClientId.value;
    final locationId = selectedLocationId.value;
    if (clientId == null || locationId == null) {
      message(
        MessageModel.info(
          title: 'Campos obrigatorios',
          message: 'Selecione o cliente e o local onde a OS sera executada.',
        ),
      );
      return;
    }

    if (!formKey.currentState!.validate()) return;

    final technicianIds = selectedTechnicianIds.toList(growable: false);

    final checklistInputs =
        checklist.map((item) => OrderChecklistInput(item: item)).toList();

    final descriptionById = <String, String>{};
    for (final item in inventoryItems) {
      final description = item.description.trim();
      if (description.isNotEmpty) {
        descriptionById[item.id] = description;
      }
    }

    final materialInputs =
        materials
            .map(
              (entry) => entry.toMaterial(
                descriptionOverride:
                    entry.itemId.value == null
                        ? null
                        : descriptionById[entry.itemId.value],
              ),
            )
            .whereType<OrderMaterialInput>()
            .toList();

    final billingInputs =
        billingItems
            .map((entry) => entry.toBilling())
            .whereType<OrderBillingItemInput>()
            .toList();

    final discount =
        double.tryParse(discountCtrl.text.replaceAll(',', '.').trim()) ?? 0;

    isLoading(true);
    try {
      final order = await _ordersService.create(
        clientId: clientId,
        locationId: locationId,
        equipmentId: selectedEquipmentId.value,
        scheduledAt: scheduledAt.value?.toUtc(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        technicianIds: technicianIds,
        checklist: checklistInputs,
        materials: materialInputs,
        billingItems: billingInputs,
        billingDiscount: discount,
      );
      final orderWithMaterials = _decorateMaterials(order);

      String? localClientName;
      for (final client in clients) {
        if (client.id == clientId) {
          final name = client.name.trim();
          if (name.isNotEmpty) localClientName = name;
          break;
        }
      }
      String? localLocationLabel;
      for (final location in locations) {
        if (location.id == locationId) {
          final parts = <String>[];
          final label = location.label.trim();
          if (label.isNotEmpty) parts.add(label);
          final address = location.addressLine.trim();
          if (address.isNotEmpty) parts.add(address);
          final cityState = location.cityState.trim();
          if (cityState.isNotEmpty) parts.add(cityState);
          if (parts.isNotEmpty) {
            localLocationLabel = parts.join(' - ');
          }
          break;
        }
      }
      String? localEquipmentLabel;
      final equipmentId = selectedEquipmentId.value;
      if (equipmentId != null && equipmentId.isNotEmpty) {
        for (final equipment in equipments) {
          if (equipment.id == equipmentId) {
            final parts = <String>[];
            final room = (equipment.room ?? '').trim();
            if (room.isNotEmpty) parts.add(room);
            final brand = (equipment.brand ?? '').trim();
            if (brand.isNotEmpty) parts.add(brand);
            final model = (equipment.model ?? '').trim();
            if (model.isNotEmpty) parts.add(model);
            final type = (equipment.type ?? '').trim();
            if (type.isNotEmpty) parts.add(type);
            if (parts.isNotEmpty) {
              localEquipmentLabel = parts.join(' - ');
            }
            break;
          }
        }
      }
      final decoratedOrder = orderWithMaterials.copyWith(
        clientName: localClientName ?? order.clientName,
        locationLabel: localLocationLabel ?? order.locationLabel,
        equipmentLabel: localEquipmentLabel ?? order.equipmentLabel,
      );
      final enrichedOrder = await _labelService.enrich(decoratedOrder);
      Get.back(result: enrichedOrder);
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro ao criar OS',
          message: _extractApiError(e),
        ),
      );
    } finally {
      if (_editingDraft != null) {
        await _draftStorage.delete(_editingDraft!.id);
        await _notifyDraftList();
        _setEditingDraft(null);
      }
      isLoading(false);
    }
  }

  Future<void> saveDraftLocally() async {
    try {
      final draft = _buildDraftModel();
      await _draftStorage.save(draft);
      _setEditingDraft(draft);
      message(
        MessageModel.success(
          title: 'Rascunho',
          message: 'Rascunho salvo no dispositivo.',
        ),
      );
      await _notifyDraftList();
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Rascunho',
          message: 'Não foi possível salvar o rascunho local.',
        ),
      );
    }
  }

  Future<void> deleteDraftLocally() async {
    final draft = _editingDraft ?? _initialDraft;
    if (draft == null) return;
    await _draftStorage.delete(draft.id);
    _setEditingDraft(null);
    await _notifyDraftList();
    Get.back(result: OrderCreateResult.draftDeleted);
    Get.snackbar('Rascunho', 'Rascunho excluído.');
  }

  Future<void> _notifyDraftList() async {
    if (Get.isRegistered<OrdersController>()) {
      await Get.find<OrdersController>().notifyDraftsChanged();
    }
  }

  OrderDraftModel _buildDraftModel() {
    final now = DateTime.now();
    final labels = _resolveLabels(
      clientId: selectedClientId.value,
      locationId: selectedLocationId.value,
      equipmentId: selectedEquipmentId.value,
    );
    final materialsData =
        materials
            .map((entry) => entry.toDraftMaterial())
            .whereType<OrderDraftMaterial>()
            .toList();
    final billingData =
        billingItems
            .map((entry) => entry.toDraftBilling())
            .whereType<OrderDraftBillingItem>()
            .toList();
    final discount =
        double.tryParse(discountCtrl.text.replaceAll(',', '.').trim()) ?? 0;

    return OrderDraftModel(
      id: _editingDraft?.id ?? OrderDraftModel.generateId(),
      createdAt: _editingDraft?.createdAt ?? now,
      updatedAt: now,
      clientId: selectedClientId.value,
      locationId: selectedLocationId.value,
      equipmentId: selectedEquipmentId.value,
      clientName: labels.clientName,
      locationLabel: labels.locationLabel,
      equipmentLabel: labels.equipmentLabel,
      scheduledAt: scheduledAt.value,
      technicianIds: selectedTechnicianIds.toList(growable: false),
      checklist: checklist.toList(growable: false),
      materials: materialsData,
      billingItems: billingData,
      billingDiscount: discount,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
  }

  _DraftLabels _resolveLabels({
    String? clientId,
    String? locationId,
    String? equipmentId,
  }) {
    String? resolvedClient;
    final client = _clientById(clientId);
    if (client != null) {
      final name = client.name.trim();
      if (name.isNotEmpty) resolvedClient = name;
    }
    String? resolvedLocation;
    final location = _locationById(locationId);
    if (location != null) {
      resolvedLocation = _formatLocationLabel(location);
    }
    String? resolvedEquipment;
    final equipment = _equipmentById(equipmentId);
    if (equipment != null) {
      resolvedEquipment = _formatEquipmentLabel(equipment);
    }
    resolvedClient ??= _editingDraft?.clientName ?? _initialDraft?.clientName;
    resolvedLocation ??=
        _editingDraft?.locationLabel ?? _initialDraft?.locationLabel;
    resolvedEquipment ??=
        _editingDraft?.equipmentLabel ?? _initialDraft?.equipmentLabel;
    return _DraftLabels(
      clientName: resolvedClient,
      locationLabel: resolvedLocation,
      equipmentLabel: resolvedEquipment,
    );
  }

  ClientModel? _clientById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final client in clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  LocationModel? _locationById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final location in locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  EquipmentModel? _equipmentById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final equipment in equipments) {
      if (equipment.id == id) return equipment;
    }
    return null;
  }

  String? _formatLocationLabel(LocationModel? model) {
    if (model == null) return null;
    final parts = <String>[];
    final label = model.label.trim();
    if (label.isNotEmpty) parts.add(label);
    if (model.addressLine.trim().isNotEmpty) {
      parts.add(model.addressLine.trim());
    }
    if (model.cityState.trim().isNotEmpty) {
      parts.add(model.cityState.trim());
    }
    return parts.isEmpty ? null : parts.join(' - ');
  }

  String? _formatEquipmentLabel(EquipmentModel? equipment) {
    if (equipment == null) return null;
    final parts = <String>[];
    final room = (equipment.room ?? '').trim();
    if (room.isNotEmpty) parts.add(room);
    final brand = (equipment.brand ?? '').trim();
    if (brand.isNotEmpty) parts.add(brand);
    final model = (equipment.model ?? '').trim();
    if (model.isNotEmpty) parts.add(model);
    final type = (equipment.type ?? '').trim();
    if (type.isNotEmpty) parts.add(type);
    return parts.isEmpty ? null : parts.join(' - ');
  }

  Future<void> _waitFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    await completer.future;
  }

  String _extractApiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      String? pick(dynamic source) {
        if (source is List) {
          for (final entry in source) {
            final detail = pick(entry);
            if (detail != null) return detail;
          }
        } else if (source is Map) {
          final message = source['message'] ?? source['detail'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
          return pick(source['errors'] ?? source['details']);
        } else if (source is String && source.trim().isNotEmpty) {
          return source.trim();
        }
        return null;
      }

      final detail =
          pick(data is Map ? data['details'] ?? data['errors'] : null) ??
          (data is Map && data['message'] is String
              ? data['message'] as String
              : null);
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return 'Nao foi possivel criar a OS.';
  }

  OrderModel _decorateMaterials(OrderModel order) {
    if (order.materials.isEmpty) return order;
    final nameById = <String, String>{};
    for (final item in inventoryItems) {
      final description = item.description.trim();
      if (description.isNotEmpty) {
        nameById[item.id] = description;
      }
    }
    for (final draft in materials) {
      final id = draft.itemId.value;
      final name = draft.itemName.value?.trim();
      if (id != null && name != null && name.isNotEmpty) {
        nameById.putIfAbsent(id, () => name);
      }
    }
    final updatedMaterials =
        order.materials.map((material) {
          final resolved = nameById[material.itemId];
          if (resolved == null || resolved.isEmpty) return material;
          return material.copyWith(itemName: resolved);
        }).toList();
    return order.copyWith(materials: updatedMaterials);
  }

  @override
  void onClose() {
    notesCtrl.dispose();
    discountCtrl.dispose();
    checklistCtrl.dispose();
    for (final m in materials) {
      m.dispose();
    }
    for (final b in billingItems) {
      b.dispose();
    }
    super.onClose();
  }
}

class _DraftLabels {
  const _DraftLabels({
    this.clientName,
    this.locationLabel,
    this.equipmentLabel,
  });

  final String? clientName;
  final String? locationLabel;
  final String? equipmentLabel;
}

final NumberFormat _draftCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

class OrderMaterialDraft {
  OrderMaterialDraft()
    : itemId = RxnString(),
      itemName = RxnString(),
      qtyCtrl = TextEditingController();

  final RxnString itemId;
  final RxnString itemName;
  final TextEditingController qtyCtrl;

  OrderMaterialInput? toMaterial({String? descriptionOverride}) {
    final id = itemId.value;
    if (id == null || id.isEmpty) return null;
    final qtyRaw = qtyCtrl.text.replaceAll(',', '.').trim();
    final qty = double.tryParse(qtyRaw);
    if (qty == null || qty <= 0) return null;
    final name = itemName.value?.trim();
    final descriptionSource = descriptionOverride?.trim();
    final resolvedDescription =
        (descriptionSource != null && descriptionSource.isNotEmpty)
            ? descriptionSource
            : (name?.isNotEmpty == true ? name : null);
    return OrderMaterialInput(
      itemId: id,
      qty: qty,
      itemName: name?.isEmpty == true ? null : name,
      description: resolvedDescription,
    );
  }

  void clearSelection() {
    itemId.value = null;
    itemName.value = null;
  }

  void dispose() => qtyCtrl.dispose();

  OrderDraftMaterial? toDraftMaterial() {
    final id = itemId.value;
    final name = itemName.value;
    final qtyRaw = qtyCtrl.text.replaceAll(',', '.').trim();
    final qty = qtyRaw.isEmpty ? null : double.tryParse(qtyRaw);
    final hasContent =
        (id != null && id.isNotEmpty) ||
        (name != null && name.trim().isNotEmpty) ||
        (qty != null && qty > 0);
    if (!hasContent) return null;
    return OrderDraftMaterial(
      itemId: id,
      itemName: name,
      description: name,
      qty: qty ?? 0,
    );
  }

  void loadFromDraft(OrderDraftMaterial data) {
    itemId.value = data.itemId;
    itemName.value = data.itemName;
    if (data.qty != null) {
      final qtyValue = data.qty!;
      final text =
          qtyValue % 1 == 0 ? qtyValue.toStringAsFixed(0) : qtyValue.toString();
      _setControllerText(qtyCtrl, text);
    } else {
      _setControllerText(qtyCtrl, '');
    }
  }
}

class OrderBillingDraft {
  OrderBillingDraft()
    : type = 'service'.obs,
      nameCtrl = TextEditingController(),
      qtyCtrl = TextEditingController(),
      unitPriceCtrl = TextEditingController();

  final RxString type;
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;

  OrderBillingItemInput? toBilling() {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return null;
    final qtyRaw = qtyCtrl.text.replaceAll(',', '.').trim();
    final digits = unitPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final qty = double.tryParse(qtyRaw);
    final unit = digits.isEmpty ? null : double.parse(digits) / 100;
    if (qty == null || qty <= 0 || unit == null || unit < 0) return null;
    return OrderBillingItemInput(
      type: type.value,
      name: name,
      qty: qty,
      unitPrice: unit,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }

  OrderDraftBillingItem? toDraftBilling() {
    final name = nameCtrl.text.trim();
    final qtyRaw = qtyCtrl.text.replaceAll(',', '.').trim();
    final qty = qtyRaw.isEmpty ? null : double.tryParse(qtyRaw);
    final digits = unitPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final unit = digits.isEmpty ? null : double.parse(digits) / 100;
    final hasContent =
        name.isNotEmpty ||
        (qty != null && qty > 0) ||
        (unit != null && unit > 0);
    if (!hasContent) return null;
    return OrderDraftBillingItem(
      type: type.value,
      name: name,
      qty: qty ?? 0,
      unitPrice: unit ?? 0,
    );
  }

  void loadFromDraft(OrderDraftBillingItem data) {
    type.value = data.type;
    _setControllerText(nameCtrl, data.name);
    final qtyText =
        data.qty % 1 == 0 ? data.qty.toStringAsFixed(0) : data.qty.toString();
    _setControllerText(qtyCtrl, qtyText);
    _setControllerText(
      unitPriceCtrl,
      _draftCurrencyFormatter.format(data.unitPrice),
    );
  }
}

void _setControllerText(TextEditingController controller, String value) {
  void setter() {
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  final phase = SchedulerBinding.instance.schedulerPhase;
  if (phase == SchedulerPhase.idle ||
      phase == SchedulerPhase.postFrameCallbacks) {
    setter();
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) => setter());
  }
}
