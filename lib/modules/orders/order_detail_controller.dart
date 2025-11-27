import 'dart:async';

import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/create_order_purchase_dto.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:air_sync/models/order_costs_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/modules/orders/orders_controller.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/company_profile/company_profile_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/orders/order_label_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:get/get.dart';

class OrderDetailController extends GetxController
    with LoaderMixin, MessagesMixin {
  OrderDetailController({
    required this.orderId,
    required OrdersService service,
    OrderLabelService? labelService,
    InventoryService? inventoryService,
    ClientService? clientService,
    LocationsService? locationsService,
    EquipmentsService? equipmentsService,
    CompanyProfileService? companyProfileService,
    UsersService? usersService,
    OrdersController? ordersController,
  }) : _service = service,
       _labelService = labelService,
       _inventoryService = inventoryService,
       _clientService = clientService,
       _locationsService = locationsService,
       _equipmentsService = equipmentsService,
       _companyProfileService = companyProfileService,
       _usersService = usersService,
       _ordersController = ordersController;

  final String orderId;
  final OrdersService _service;
  final OrderLabelService? _labelService;
  final InventoryService? _inventoryService;
  final ClientService? _clientService;
  final LocationsService? _locationsService;
  final EquipmentsService? _equipmentsService;
  final CompanyProfileService? _companyProfileService;
  final UsersService? _usersService;
  final OrdersController? _ordersController;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final Rxn<OrderModel> order = Rxn<OrderModel>();
  final Rxn<OrderCostsModel> costSummary = Rxn<OrderCostsModel>();
  final RxBool costSummaryLoading = false.obs;
  final RxnString costSummaryError = RxnString();
  final RxBool assistantLoading = false.obs;
  final RxBool summaryLoading = false.obs;
  List<InventoryItemModel>? _inventoryCache;
  CompanyProfileModel? _profileCache;
  List<CollaboratorModel>? _techniciansCache;
  ClientModel? _clientCache;
  LocationModel? _locationCache;
  EquipmentModel? _equipmentCache;
  final Map<String, InventoryItemModel> _materialCatalogCache = {};

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await load();
    super.onReady();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final data = await _service.getById(orderId);
      await _setOrder(data);
      unawaited(_loadCostSummary());
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao carregar detalhes da OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> startOrder() async {
    isLoading(true);
    try {
      final updated = await _service.start(orderId);
      await _setOrder(updated);
      unawaited(_loadCostSummary());
      message(MessageModel.success(title: 'OS', message: 'Ordem iniciada.'));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível iniciar a OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateOrder({
    String? status,
    DateTime? scheduledAt,
    List<String>? technicianIds,
    List<OrderChecklistInput>? checklist,
    List<OrderBillingItemInput>? billingItems,
    num? billingDiscount,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final updated = await _service.update(
        orderId: orderId,
        status: status,
        scheduledAt: scheduledAt,
        technicianIds: technicianIds,
        checklist: checklist,
        billingItems: billingItems,
        billingDiscount: billingDiscount,
        notes: notes,
      );
      await _setOrder(updated);
      unawaited(_loadCostSummary());
      message(MessageModel.success(title: 'OS', message: 'Dados atualizados.'));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível atualizar a OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<bool> finishOrder({
    required List<OrderBillingItemInput> billingItems,
    num discount = 0,
    String? signatureBase64,
    String? notes,
    List<OrderPaymentInput> payments = const [],
  }) async {
    isLoading(true);
    try {
      final updated = await _service.finish(
        orderId: orderId,
        billingItems: billingItems,
        discount: discount,
        signatureBase64: signatureBase64,
        notes: notes,
        payments: payments,
      );
      await _setOrder(updated);
      unawaited(_loadCostSummary());
      message(MessageModel.success(title: 'OS', message: 'Ordem finalizada.'));
      return true;
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível finalizar a OS.',
        ),
      );
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> rescheduleOrder({
    required DateTime scheduledAt,
    String? notes,
  }) async {
    isLoading(true);
    try {
      final updated = await _service.reschedule(
        orderId: orderId,
        scheduledAt: scheduledAt,
        notes: notes,
      );
      await _setOrder(updated);
      unawaited(_loadCostSummary());
      message(
        MessageModel.success(title: 'OS', message: 'Reagendada com sucesso.'),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível reagendar a OS.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> reserveMaterials(List<OrderMaterialInput> materials) async {
    if (materials.isEmpty) return;
    isLoading(true);
    try {
      await _service.reserveMaterials(orderId, materials);
      await load();
      message(
        MessageModel.success(
          title: 'Materiais',
          message: 'Materiais reservados.',
        ),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível reservar materiais.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deductMaterials(List<OrderMaterialInput> materials) async {
    if (materials.isEmpty) return;
    isLoading(true);
    try {
      await _service.deductMaterials(orderId, materials);
      await load();
      message(
        MessageModel.success(
          title: 'Materiais',
          message: 'Materiais baixados.',
        ),
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível baixar materiais.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<String> uploadPhoto({
    required String filename,
    required List<int> bytes,
  }) async {
    try {
      final url = await _service.uploadPhoto(
        orderId: orderId,
        filename: filename,
        bytes: bytes,
      );
      await load();
      return url;
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Upload',
          message: 'Não foi possível enviar a foto.',
        ),
      );
      rethrow;
    }
  }

  Future<String> uploadSignature(String base64) async {
    try {
      final url = await _service.uploadSignature(
        orderId: orderId,
        base64: base64,
      );
      await load();
      message(
        MessageModel.success(
          title: 'Assinatura',
          message: 'Assinatura anexada com sucesso.',
        ),
      );
      return url;
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Assinatura',
          message: 'Não foi possível registrar a assinatura.',
        ),
      );
      rethrow;
    }
  }

  String pdfUrl({String type = 'report'}) =>
      _service.pdfUrl(orderId, type: type);

  Future<List<InventoryItemModel>> fetchInventoryItems() async {
    if (_inventoryCache != null) return _inventoryCache!;
    final svc = _inventoryService;
    if (svc == null) return const [];
    try {
      final legacyItems = await svc.getItems(limit: 200);
      if (legacyItems.isNotEmpty) {
        _inventoryCache = legacyItems;
        return legacyItems;
      }
    } catch (_) {}

    try {
      final modernItems = await svc.listItems(q: '');
      if (modernItems.isNotEmpty) {
        _inventoryCache = modernItems;
        return modernItems;
      }
    } catch (_) {}

    return const [];
  }

  Future<CompanyProfileModel?> fetchCompanyProfile() async {
    if (_profileCache != null) return _profileCache;
    final svc = _companyProfileService;
    if (svc == null) return null;
    try {
      _profileCache = await svc.loadProfile();
      return _profileCache;
    } catch (_) {
      return null;
    }
  }

  Future<List<CollaboratorModel>> fetchTechnicians() async {
    if (_techniciansCache != null) return _techniciansCache!;
    final svc = _usersService;
    if (svc == null) return const [];
    try {
      final list = await svc.list(role: CollaboratorRole.tech);
      _techniciansCache = list;
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<OrderPdfData?> preparePdfData() async {
    final currentOrder = order.value;
    if (currentOrder == null) {
      message(
        MessageModel.error(
          title: 'PDF',
          message: 'Carregue a OS antes de gerar o PDF.',
        ),
      );
      return null;
    }
    isLoading(true);
    try {
      final client = await _resolveClient(currentOrder.clientId);
      final location = await _resolveLocation(
        clientId: currentOrder.clientId,
        locationId: currentOrder.locationId,
      );
      final equipment = await _resolveEquipment(
        clientId: currentOrder.clientId,
        locationId: currentOrder.locationId,
        equipmentId: currentOrder.equipmentId,
      );
      final technicians = await _resolveTechnicians(currentOrder.technicianIds);
      final materialCatalog = await _resolveMaterialCatalog(currentOrder);
      return OrderPdfData(
        order: currentOrder,
        client: client,
        location: location,
        equipment: equipment,
        technicians: technicians,
        materialCatalog: materialCatalog,
      );
    } catch (_) {
      message(
        MessageModel.error(
          title: 'PDF',
          message: 'Não foi possível montar os dados para o PDF.',
        ),
      );
      return null;
    } finally {
      isLoading(false);
    }
  }

  Future<ClientModel?> _resolveClient(String clientId) async {
    final trimmed = clientId.trim();
    if (trimmed.isEmpty) return null;
    final cached = _clientCache;
    if (cached != null && cached.id == trimmed) return cached;
    final svc = _clientService;
    if (svc == null) return null;
    try {
      final client = await svc.getById(trimmed);
      _clientCache = client;
      return client;
    } catch (_) {
      return null;
    }
  }

  Future<LocationModel?> _resolveLocation({
    required String clientId,
    required String locationId,
  }) async {
    final trimmed = locationId.trim();
    if (trimmed.isEmpty) return null;
    final cached = _locationCache;
    if (cached != null && cached.id == trimmed) return cached;
    final svc = _locationsService;
    if (svc == null) return null;
    try {
      final locations = await svc.listByClient(clientId);
      for (final location in locations) {
        if (location.id == trimmed) {
          _locationCache = location;
          return location;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<EquipmentModel?> _resolveEquipment({
    required String clientId,
    required String locationId,
    String? equipmentId,
  }) async {
    final trimmed = equipmentId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final cached = _equipmentCache;
    if (cached != null && cached.id == trimmed) return cached;
    final svc = _equipmentsService;
    if (svc == null) return null;
    try {
      final equipments = await svc.listBy(
        clientId,
        locationId: locationId.trim().isEmpty ? null : locationId,
      );
      for (final equipment in equipments) {
        if (equipment.id == trimmed) {
          _equipmentCache = equipment;
          return equipment;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<CollaboratorModel>> _resolveTechnicians(
    List<String> technicianIds,
  ) async {
    if (technicianIds.isEmpty) return const [];
    final catalog = await fetchTechnicians();
    if (catalog.isEmpty) return const [];
    final idSet =
        technicianIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet();
    if (idSet.isEmpty) return const [];
    final selected = <CollaboratorModel>[];
    for (final tech in catalog) {
      if (idSet.contains(tech.id)) {
        selected.add(tech);
      }
    }
    return selected;
  }

  Future<Map<String, InventoryItemModel>> _resolveMaterialCatalog(
    OrderModel currentOrder,
  ) async {
    if (currentOrder.materials.isEmpty) return const {};
    final ids =
        currentOrder.materials
            .map((m) => m.itemId.trim())
            .where((id) => id.isNotEmpty)
            .toSet();
    if (ids.isEmpty) return const {};
    final svc = _inventoryService;
    if (svc == null) return const {};

    InventoryItemModel? lookupLocal(String id) {
      final cached = _materialCatalogCache[id];
      if (cached != null) return cached;
      final list = _inventoryCache;
      if (list != null) {
        for (final item in list) {
          if (item.id == id) return item;
        }
      }
      return null;
    }

    final map = <String, InventoryItemModel>{};
    final missing = <String>[];
    for (final id in ids) {
      final cached = lookupLocal(id);
      if (cached != null) {
        map[id] = cached;
        _materialCatalogCache[id] = cached;
      } else {
        missing.add(id);
      }
    }

    for (final id in missing) {
      try {
        final item = await svc.getItem(id);
        map[id] = item;
        _materialCatalogCache[id] = item;
      } catch (_) {
        // ignore items not found
      }
    }

    return map;
  }

  Future<void> _setOrder(OrderModel value) async {
    final labeler = _labelService;
    if (labeler == null) {
      order.value = value;
      _ordersController?.upsertOrder(value);
      return;
    }
    try {
      final enriched = await labeler.enrich(value);
      order.value = enriched;
      _ordersController?.upsertOrder(enriched);
    } catch (_) {
      order.value = value;
      _ordersController?.upsertOrder(value);
    }
  }

  Future<void> refreshCostSummary() => _loadCostSummary();

  Future<void> _loadCostSummary() async {
    costSummaryLoading(true);
    costSummaryError.value = null;
    try {
      final summary = await _service.getCosts(orderId);
      if (summary == null) {
        costSummary.value = null;
        costSummaryError.value = 'Nenhuma informação de custo disponível.';
      } else {
        costSummary.value = summary;
      }
    } catch (_) {
      costSummaryError.value = 'Falha ao carregar os custos da OS.';
    } finally {
      costSummaryLoading(false);
    }
  }

  Future<PurchaseModel?> createPurchaseForOrder({
    required CreateOrderPurchaseDto dto,
  }) async {
    isLoading(true);
    try {
      final purchase = await _service.createPurchaseFromOrder(
        orderId: orderId,
        dto: dto,
      );
      message(
        MessageModel.success(
          title: 'Compras',
          message: 'Compra ${purchase.id} criada para esta OS.',
        ),
      );
      unawaited(_loadCostSummary());
      return purchase;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Compras',
          message: 'Falha ao criar compra: $e',
        ),
      );
      return null;
    } finally {
      isLoading(false);
    }
  }

  Future<String?> fetchAssistantAnswer(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return null;
    assistantLoading(true);
    try {
      final answer = await _service.askTechnicalAssistant(
        orderId: orderId,
        question: trimmed,
      );
      final normalized = answer.trim();
      if (normalized.isEmpty) return null;
      return normalized;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Assistente técnico',
          message: 'Falha ao consultar o assistente: $e',
        ),
      );
      return null;
    } finally {
      assistantLoading(false);
    }
  }

  Future<String?> fetchCustomerSummary() async {
    summaryLoading(true);
    try {
      final summary = await _service.generateCustomerSummary(orderId);
      final normalized = summary.trim();
      if (normalized.isEmpty) {
        message(
          MessageModel.info(
            title: 'Resumo',
            message: 'Nenhum texto foi retornado pelo assistente.',
          ),
        );
        return null;
      }
      return normalized;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Resumo',
          message: 'Não foi possível gerar o resumo: $e',
        ),
      );
      return null;
    } finally {
      summaryLoading(false);
    }
  }
}

class OrderPdfData {
  const OrderPdfData({
    required this.order,
    this.client,
    this.location,
    this.equipment,
    this.technicians = const [],
    this.materialCatalog = const {},
  });

  final OrderModel order;
  final ClientModel? client;
  final LocationModel? location;
  final EquipmentModel? equipment;
  final List<CollaboratorModel> technicians;
  final Map<String, InventoryItemModel> materialCatalog;
}
