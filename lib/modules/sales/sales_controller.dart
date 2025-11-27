import 'dart:async';

import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/cost_center_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/sale_model.dart';
import 'package:air_sync/modules/orders/order_detail_bindings.dart';
import 'package:air_sync/modules/orders/order_detail_page.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/sales/sales_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesController extends GetxController with LoaderMixin, MessagesMixin {
  SalesController({
    required SalesService service,
    required CostCentersService costCentersService,
    required ClientService clientService,
    required InventoryService inventoryService,
    required LocationsService locationsService,
  })  : _service = service,
        _costCentersService = costCentersService,
        _clientService = clientService,
        _inventoryService = inventoryService,
        _locationsService = locationsService;

  final SalesService _service;
  final CostCentersService _costCentersService;
  final ClientService _clientService;
  final InventoryService _inventoryService;
  final LocationsService _locationsService;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final sales = <SaleModel>[].obs;
  final statusFilter = 'all'.obs;
  final searchCtrl = TextEditingController();
  final RxString searchTerm = ''.obs;
  final RxList<CostCenterModel> costCenters = <CostCenterModel>[].obs;
  final RxBool costCentersLoading = false.obs;
  Timer? _searchDebounce;

  List<SaleModel> get filteredSales {
    final text = searchTerm.value.trim().toLowerCase();
    final status = statusFilter.value;
    return sales.where((sale) {
      final matchesStatus =
          status == 'all' ? true : sale.status.toLowerCase() == status.toLowerCase();
      final matchesText =
          text.isEmpty
              ? true
              : sale.displayTitle.toLowerCase().contains(text) ||
                  ((sale.clientName ?? sale.customerName ?? '').toLowerCase().contains(text)) ||
                  (sale.linkedOrderId ?? '').toLowerCase().contains(text);
      return matchesStatus && matchesText;
    }).toList();
  }

  @override
  void onInit() {
    messageListener(message);
    loaderListener(isLoading);
    _init();
    super.onInit();
  }

  Future<void> _init() async {
    await Future.wait([load(), _loadCostCenters()]);
  }

  Future<void> load({bool refresh = false}) async {
    if (isLoading.value) return;
    isLoading(true);
    try {
      final results = await _service.list(
        status: statusFilter.value == 'all' ? null : statusFilter.value,
        search: searchTerm.value.isEmpty ? null : searchTerm.value,
      );
      sales.assignAll(results);
    } finally {
      isLoading(false);
    }
  }

  void setStatusFilter(String value) {
    if (statusFilter.value == value) {
      statusFilter.value = 'all';
    } else {
      statusFilter.value = value;
    }
    unawaited(load(refresh: true));
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      searchTerm.value = value;
      load();
    });
  }

  Future<void> _loadCostCenters() async {
    try {
      costCentersLoading(true);
      final result = await _costCentersService.list(includeInactive: false);
      costCenters.assignAll(result);
    } finally {
      costCentersLoading(false);
    }
  }

  Future<void> createSale({
    required String clientId,
    required String locationId,
    required List<SaleItemModel> items,
    double? discount,
    String? notes,
    Map<String, dynamic>? moveRequest,
    String? costCenterId,
    bool autoCreateOrder = false,
  }) async {
    if (items.isEmpty) {
      message(
        MessageModel.error(
          title: 'Vendas',
          message: 'Adicione pelo menos um item à venda.',
        ),
      );
      return;
    }
    isLoading(true);
    try {
      final sale = await _service.create(
        clientId: clientId,
        locationId: locationId,
        items: items,
        discount: discount,
        notes: notes,
        moveRequest: moveRequest,
        costCenterId: costCenterId,
        autoCreateOrder: autoCreateOrder,
      );
      _replaceSale(sale);
      message(
        MessageModel.success(
          title: 'Vendas',
          message: 'Venda criada com sucesso',
        ),
      );
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao criar venda: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateSale({
    required String id,
    String? clientId,
    String? locationId,
    List<SaleItemModel>? items,
    double? discount,
    String? notes,
    Map<String, dynamic>? moveRequest,
    String? costCenterId,
    bool? autoCreateOrder,
  }) async {
    isLoading(true);
    try {
      final sale = await _service.update(
        id,
        clientId: clientId,
        locationId: locationId,
        items: items,
        discount: discount,
        notes: notes,
        moveRequest: moveRequest,
        costCenterId: costCenterId,
        autoCreateOrder: autoCreateOrder,
      );
      _replaceSale(sale);
      message(
        MessageModel.success(
          title: 'Vendas',
          message: 'Venda atualizada',
        ),
      );
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao atualizar venda: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> approveSale(String id, {bool forceOrder = false}) => _transition(
        () => _service.approve(id, forceOrder: forceOrder),
        success: forceOrder ? 'Venda aprovada e OS gerada' : 'Venda aprovada',
      );

  Future<void> fulfillSale(String id) => _transition(
        () => _service.fulfill(id),
        success: 'Venda marcada como atendida',
      );

  Future<void> cancelSale(String id, {String? reason}) => _transition(
        () => _service.cancel(id, reason: reason),
        success: 'Venda cancelada',
      );

  Future<void> launchOrder({
    required SaleModel sale,
    bool force = false,
  }) async {
    final alreadyLinked = (sale.linkedOrderId ?? '').isNotEmpty;
    if (alreadyLinked && !force) {
      message(
        MessageModel.info(
          title: 'Vendas',
          message: 'Esta venda já possui a OS ${sale.linkedOrderId}.',
        ),
      );
      return;
    }
    final status = sale.status.toLowerCase();
    final approvedStatuses = {'approved', 'fulfilled'};
    if (!approvedStatuses.contains(status) && !force) {
      message(
        MessageModel.info(
          title: 'Vendas',
          message: 'A venda precisa estar aprovada antes de gerar uma OS.',
        ),
      );
      return;
    }
    isLoading(true);
    try {
      final updated = await _service.launchOrderIfNeeded(
        sale.id,
        force: force,
      );
      _replaceSale(updated);
      if ((updated.linkedOrderId ?? '').isEmpty) {
        message(
          MessageModel.info(
            title: 'Vendas',
            message: 'Nenhuma OS foi vinculada. Tente novamente mais tarde.',
          ),
        );
      } else {
        message(
          MessageModel.success(
            title: 'Vendas',
            message: 'OS ${updated.linkedOrderId} vinculada à venda.',
          ),
        );
      }
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao gerar OS: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _transition(
    Future<SaleModel> Function() call, {
    required String success,
  }) async {
    isLoading(true);
    try {
      final sale = await call();
      _replaceSale(sale);
      message(
        MessageModel.success(
          title: 'Vendas',
          message: success,
        ),
      );
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: e.toString(),
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  void _replaceSale(SaleModel sale) {
    final idx = sales.indexWhere((element) => element.id == sale.id);
    if (idx == -1) {
      sales.insert(0, sale);
    } else {
      sales[idx] = sale;
    }
    sales.refresh();
  }

  void openLinkedOrder(String orderId) {
    if (orderId.trim().isEmpty) return;
    Get.to(
      () => const OrderDetailPage(),
      binding: OrderDetailBindings(orderId: orderId),
    );
  }

  Future<String?> generateProposalText(String saleId) async {
    try {
      final text = await _service.generateProposal(saleId);
      final normalized = text.trim();
      if (normalized.isEmpty) {
        message(
          MessageModel.info(
            title: 'Vendas',
            message: 'Nenhuma proposta foi retornada.',
          ),
        );
        return null;
      }
      return normalized;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Vendas',
          message: 'Falha ao gerar proposta: $e',
        ),
      );
      return null;
    }
  }

  Future<String?> askCommercialAssistant(String saleId, String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return null;
    try {
      final answer = await _service.commercialAssistant(saleId, trimmed);
      final normalized = answer.trim();
      if (normalized.isEmpty) {
        message(
          MessageModel.info(
            title: 'Vendas',
            message: 'O assistente não retornou uma resposta.',
          ),
        );
        return null;
      }
      return normalized;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Vendas',
          message: 'Falha ao consultar o assistente comercial: $e',
        ),
      );
      return null;
    }
  }

  Future<List<ClientModel>> fetchClients(String text) async {
    try {
      final results = await _clientService.list(
        text: text.isEmpty ? null : text,
        limit: 50,
      );
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<List<LocationModel>> fetchLocations(String clientId) async {
    final trimmed = clientId.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final locations = await _locationsService.listByClient(trimmed);
      return locations;
    } catch (_) {
      return const [];
    }
  }

  Future<List<InventoryItemModel>> fetchInventory({
    String? search,
  }) async {
    try {
      final items = await _inventoryService.listItems(
        q: (search ?? '').isEmpty ? null : search,
        limit: 100,
      );
      return items;
    } catch (_) {
      return const [];
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }
}

