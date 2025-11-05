import 'package:air_sync/application/core/errors/inventory_failure.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderCreateController extends GetxController
    with LoaderMixin, MessagesMixin {
  OrderCreateController({
    required OrdersService ordersService,
    required ClientService clientService,
    required LocationsService locationsService,
    required EquipmentsService equipmentsService,
    required InventoryService inventoryService,
  }) : _ordersService = ordersService,
       _clientService = clientService,
       _locationsService = locationsService,
       _equipmentsService = equipmentsService,
       _inventoryService = inventoryService;

  final OrdersService _ordersService;
  final ClientService _clientService;
  final LocationsService _locationsService;
  final EquipmentsService _equipmentsService;
  final InventoryService _inventoryService;

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

  final TextEditingController techniciansCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();

  final RxList<String> checklist = <String>[].obs;
  final TextEditingController checklistCtrl = TextEditingController();

  final RxList<OrderMaterialDraft> materials = <OrderMaterialDraft>[].obs;
  final RxList<OrderBillingDraft> billingItems = <OrderBillingDraft>[].obs;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await _loadClients();
    await _loadInventoryItems();
    if (materials.isEmpty) addMaterialRow();
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
      final items = await _inventoryService.listItems(limit: 200);
      final filtered =
          items.where((item) => item.active).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
      inventoryItems.assignAll(filtered);
    } on InventoryFailure catch (e) {
      inventoryError.value = e.message;
    } catch (_) {
      inventoryError.value = 'Não foi possível carregar os itens do estoque.';
    } finally {
      isInventoryLoading(false);
    }
  }

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
          title: 'Endereços',
          message: 'Falha ao carregar endereços.',
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
          title: 'Campos obrigatórios',
          message: 'Selecione o cliente e o local onde a OS será executada.',
        ),
      );
      return;
    }

    if (!formKey.currentState!.validate()) return;

    final technicianIds =
        techniciansCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final checklistInputs =
        checklist.map((item) => OrderChecklistInput(item: item)).toList();

    final materialInputs =
        materials
            .map((entry) => entry.toMaterial())
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
        status: 'scheduled',
        scheduledAt: scheduledAt.value?.toUtc(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        technicianIds: technicianIds,
        checklist: checklistInputs,
        materials: materialInputs,
        billingItems: billingInputs,
        billingDiscount: discount,
      );
      message(
        MessageModel.success(
          title: 'OS criada',
          message: 'A ordem foi cadastrada com sucesso.',
        ),
      );
      Get.back(result: order);
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro ao criar OS',
          message: _extractApiError(e),
        ),
      );
    } finally {
      isLoading(false);
    }
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
    return 'Não foi possível criar a OS.';
  }

  @override
  void onClose() {
    techniciansCtrl.dispose();
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

class OrderMaterialDraft {
  OrderMaterialDraft()
    : itemId = RxnString(),
      qtyCtrl = TextEditingController();

  final RxnString itemId;
  final TextEditingController qtyCtrl;

  OrderMaterialInput? toMaterial() {
    final id = itemId.value;
    if (id == null || id.isEmpty) return null;
    final qtyRaw = qtyCtrl.text.replaceAll(',', '.').trim();
    final qty = double.tryParse(qtyRaw);
    if (qty == null || qty <= 0) return null;
    return OrderMaterialInput(itemId: id, qty: qty);
  }

  void dispose() => qtyCtrl.dispose();
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
}
