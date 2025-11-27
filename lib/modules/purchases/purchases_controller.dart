import 'dart:async';

import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/modules/purchases/models/purchase_prefill.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PurchasesController extends GetxController
    with LoaderMixin, MessagesMixin {
  final PurchasesService _service;
  PurchasesController({required PurchasesService service}) : _service = service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <PurchaseModel>[].obs;
  final supplierNames = <String, String>{}.obs;
  final filter = ''.obs;
  final itemNames = <String, String>{}.obs;
  final searchCtrl = TextEditingController();
  final RxString searchTerm = ''.obs;
  final RxString statusFilter = 'all'.obs;
  final RxBool alertsOnly = false.obs;
  final Rxn<DateTime> monthFilter = Rxn<DateTime>(
    DateTime(DateTime.now().year, DateTime.now().month),
  );
  final RxInt yearFilter = DateTime.now().year.obs;
  Timer? _searchDebounce;
  PurchasePrefillData? _pendingPrefill;

  bool get hasFiltersApplied =>
      statusFilter.value != 'all' ||
      filter.value.isNotEmpty ||
      monthFilter.value != null ||
      alertsOnly.value;

  @override
  Future<void> onInit() async {
    final args = Get.arguments;
    if (args is Map) {
      if (args['initialFilter'] is String) {
        final initial = args['initialFilter'].toString();
        filter.value = initial.toLowerCase();
        searchCtrl.text = initial;
      }
      if (args['statusFilter'] is String) {
        statusFilter.value = args['statusFilter'].toString();
      }
      if (args['prefillPurchase'] is PurchasePrefillData) {
        _pendingPrefill = args['prefillPurchase'] as PurchasePrefillData;
      }
    }
    // Evita abrir loader modal no primeiro carregamento
    messageListener(message);
    await load();
    loaderListener(isLoading);
    super.onInit();
  }

  Future<void> load() async {
    isLoading(true);
    try {
      final list = await _service.list();
      items.assignAll(list);
      await _populateSupplierNames();
      _alignYearFilterWithData();
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Compras',
          message: 'Falha ao carregar as compras: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _populateSupplierNames() async {
    try {
      final svc =
          Get.isRegistered<SuppliersService>() ? Get.find<SuppliersService>() : null;
      if (svc == null) return;
      final suppliers = await svc.list(text: '');
      supplierNames.assignAll({for (final s in suppliers) s.id: s.name});
    } catch (_) {
      // ignore lookup errors; fallback to showing supplierId
    }
  }

  String supplierNameFor(String supplierId) =>
      supplierNames[supplierId] ?? supplierId;

  Future<void> ensureItemNamesLoaded() async {
    if (itemNames.isNotEmpty) return;
    try {
      final inv = Get.find<InventoryService>();
      final all = await inv.getItems(text: '');
      itemNames.assignAll({for (final it in all) it.id: it.name});
    } catch (_) {}
  }

  Future<PurchaseModel?> create({
    required String supplierId,
    required List<PurchaseItemModel> items,
    String status = 'ordered',
    double? freight,
    String? notes,
    DateTime? paymentDueDate,
  }) async {
    isLoading(true);
    try {
      final p = await _service.create(
        supplierId: supplierId,
        items: items,
        status: status,
        freight: freight,
        notes: notes,
        paymentDueDate: paymentDueDate,
      );
      this.items.insert(0, p);
      message(MessageModel.info(title: 'Compra criada', message: p.id));
      if (!supplierNames.containsKey(supplierId)) {
        await _populateSupplierNames();
      }
      if (status.toLowerCase() == 'received' &&
          p.status.toLowerCase() == 'received') {
        await _refreshInventoryAfterReceive(purchaseId: p.id, items: items);
      }
      _handleNotification(p, fallback: 'Compra criada e sincronizada.');
      return p;
    } catch (e) {
      final errMsg = e.toString();
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao criar compra. $errMsg',
        ),
      );
      return null;
    } finally {
      isLoading(false);
    }
  }

  Future<void> receive(String id, {DateTime? receivedAt}) async {
    isLoading(true);
    try {
      await _service.receive(id: id, receivedAt: receivedAt);
      final idx = items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final previous = items[idx];
        final updatedPurchase = previous.copyWith(
          status: 'received',
          receivedAt: receivedAt ?? DateTime.now(),
        );
        items[idx] = updatedPurchase;
        items.refresh();
        await _refreshInventoryAfterReceive(
          purchaseId: id,
          items: updatedPurchase.items,
        );
        _handleNotification(
          updatedPurchase,
          fallback: 'Confirmação de recebimento registrada.',
        );
      }
      message(
        MessageModel.success(
          title: 'Compras',
          message: 'Compra recebida com sucesso',
        ),
      );
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao receber compra: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<PurchaseModel?> updatePurchase({
    required String id,
    String? supplierId,
    List<PurchaseItemModel>? items,
    String? status,
    double? freight,
    String? notes,
    DateTime? paymentDueDate,
  }) async {
    isLoading(true);
    try {
      final updated = await _service.update(
        id: id,
        supplierId: supplierId,
        items: items,
        status: status,
        freight: freight,
        notes: notes,
        paymentDueDate: paymentDueDate,
      );
      final idx = this.items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        final previousStatus = this.items[idx].status.toLowerCase();
        this.items[idx] = updated;
        this.items.refresh();
        if (previousStatus != 'received' &&
            updated.status.toLowerCase() == 'received') {
          await _refreshInventoryAfterReceive(
            purchaseId: id,
            items: updated.items,
          );
        }
      }
      message(
        MessageModel.success(title: 'Compras', message: 'Compra atualizada'),
      );
      _handleNotification(updated);
      return updated;
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao atualizar compra: $e',
        ),
      );
      return null;
    } finally {
      isLoading(false);
    }
  }

  void _registerPurchaseMovements(
    String purchaseId,
    List<PurchaseItemModel> purchaseItems,
  ) {
    if (!Get.isRegistered<InventoryController>()) return;
    final inventoryController = Get.find<InventoryController>();
    for (final line in purchaseItems) {
      inventoryController.registerLocalMovement(
        itemId: line.itemId,
        quantity: line.qty,
        type: MovementType.receive,
        reason: 'Compra recebida',
        documentRef: purchaseId,
      );
    }
  }

  Future<void> _refreshInventoryAfterReceive({
    String? purchaseId,
    List<PurchaseItemModel>? items,
  }) async {
    try {
      if (Get.isRegistered<InventoryController>()) {
        final inventoryController = Get.find<InventoryController>();
        await inventoryController.refreshCurrentView(showLoader: false);
        inventoryController.scheduleRefresh(
          delay: const Duration(milliseconds: 400),
          showLoader: false,
        );
        if (purchaseId != null && items != null && items.isNotEmpty) {
          _registerPurchaseMovements(purchaseId, items);
        }
      }
    } catch (_) {}
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    searchTerm.value = normalized;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      filter.value = normalized;
    });
  }

  List<DateTime> get monthOptions {
    final year = yearFilter.value;
    return List<DateTime>.generate(12, (index) => DateTime(year, index + 1));
  }

  List<int> get yearOptions {
    final years = <int>{yearFilter.value, ..._dataYears};
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    while (list.length < 3) {
      final last = list.isEmpty ? DateTime.now().year : list.last;
      list.add(last - 1);
    }
    return list;
  }

  Set<int> monthsWithDataForYear(int year) {
    final set = <int>{};
    for (final purchase in items) {
      final date = purchase.createdAt ?? purchase.receivedAt;
      if (date == null) continue;
      if (date.year == year) {
        set.add(date.month);
      }
    }
    return set;
  }

  Set<int> get _dataYears {
    final years = <int>{};
    for (final purchase in items) {
      final date = purchase.createdAt ?? purchase.receivedAt;
      if (date != null) {
        years.add(date.year);
      }
    }
    return years;
  }

  void _alignYearFilterWithData() {
    final dataYears = _dataYears;
    if (dataYears.isEmpty) return;
    if (!dataYears.contains(yearFilter.value)) {
      yearFilter.value = dataYears.reduce((a, b) => a > b ? a : b);
      monthFilter.value = null;
    }
  }

  List<PurchaseModel> get filteredItems {
    final query = filter.value.trim().toLowerCase();
    Iterable<PurchaseModel> filtered = items;
    if (query.isNotEmpty) {
      filtered = filtered.where((purchase) {
        final supplier = supplierNameFor(purchase.supplierId).toLowerCase();
        final statusPt = statusLabel(purchase.status).toLowerCase();
        return supplier.contains(query) ||
            statusPt.contains(query) ||
            purchase.id.toLowerCase().contains(query);
      });
    }

    final selectedYear = yearFilter.value;
    filtered = filtered.where((purchase) {
      final date = purchase.createdAt ?? purchase.receivedAt;
      if (date == null) return false;
      return date.year == selectedYear;
    });

    final selectedMonth = monthFilter.value;
    if (selectedMonth != null) {
      filtered = filtered.where((purchase) {
        final date = purchase.createdAt ?? purchase.receivedAt;
        if (date == null) return false;
        return date.year == selectedMonth.year &&
            date.month == selectedMonth.month;
      });
    }

    switch (statusFilter.value) {
      case 'pending':
        filtered = filtered.where(
          (purchase) => purchase.status.toLowerCase() == 'pending',
        );
        break;
      case 'submitted':
        filtered = filtered.where(
          (purchase) => purchase.status.toLowerCase() == 'submitted',
        );
        break;
      case 'approved':
        filtered = filtered.where(
          (purchase) => purchase.status.toLowerCase() == 'approved',
        );
        break;
      case 'ordered':
        filtered = filtered.where(
          (purchase) => purchase.status.toLowerCase() == 'ordered',
        );
        break;
      case 'received':
        filtered = filtered.where(
          (purchase) => purchase.status.toLowerCase() == 'received',
        );
        break;
      case 'canceled':
        filtered = filtered.where(
          (purchase) =>
              purchase.status.toLowerCase() == 'canceled' ||
              purchase.status.toLowerCase() == 'cancelled',
        );
        break;
      case 'all':
        break;
      default:
        filtered = filtered.where(
          (purchase) => purchase.status.toLowerCase() == statusFilter.value,
        );
        break;
    }
    return filtered.toList();
  }

  String statusLabel(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'draft') return 'Rascunho';
    if (normalized == 'pending') return 'Pendente';
    if (normalized == 'submitted') return 'Enviada';
    if (normalized == 'approved') return 'Aprovada';
    if (normalized == 'ordered') return 'Pedido';
    if (normalized == 'received') return 'Recebida';
    if (normalized == 'canceled' || normalized == 'cancelled') {
      return 'Cancelada';
    }
    return status;
  }

  bool canReceive(PurchaseModel purchase) {
    final s = purchase.status.toLowerCase();
    return s == 'ordered';
  }

  bool isOpenPurchase(PurchaseModel purchase) {
    final s = purchase.status.toLowerCase();
    return s != 'received' && s != 'canceled' && s != 'cancelled';
  }

  double subtotalFor(PurchaseModel purchase) {
    return purchase.subtotal ??
        purchase.items.fold<double>(
          0,
          (sum, item) => sum + (item.qty * item.unitCost),
        );
  }

  double totalFor(PurchaseModel purchase) {
    final subtotal = subtotalFor(purchase);
    if (purchase.total > 0) return purchase.total;
    return subtotal + (purchase.freight ?? 0);
  }

  Future<void> cancel(String id, {String? reason}) async {
    isLoading(true);
    try {
      final updated = await _service.cancel(id: id, reason: reason);
      _replaceItem(updated);
      message(
        MessageModel.success(
          title: 'Compras',
          message: 'Compra cancelada com sucesso.',
        ),
      );
      _handleNotification(updated);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível cancelar a compra.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> submitPurchase(String id, {String? notes}) async {
    isLoading(true);
    try {
      final updated = await _service.submit(id, notes: notes);
      _replaceItem(updated);
      message(
        MessageModel.success(
          title: 'Compras',
          message: 'Compra enviada para aprovacao.',
        ),
      );
      _handleNotification(updated, fallback: 'Workflow: compra submetida.');
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao enviar compra: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> approvePurchase(String id, {String? notes}) async {
    isLoading(true);
    try {
      final updated = await _service.approve(id, notes: notes);
      _replaceItem(updated);
      message(
        MessageModel.success(
          title: 'Compras',
          message: 'Compra aprovada.',
        ),
      );
      _handleNotification(updated, fallback: 'Workflow: compra aprovada.');
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao aprovar compra: $e',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> markAsOrdered(String id, {String? externalId}) async {
    isLoading(true);
    try {
      final updated =
          await _service.markAsOrdered(id, externalId: externalId);
      _replaceItem(updated);
      message(
        MessageModel.success(
          title: 'Compras',
          message: 'Compra marcada como pedido.',
        ),
      );
      _handleNotification(updated, fallback: 'Workflow: pedido confirmado.');
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Falha ao marcar pedido: $e',
        ),
      );
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
  }

  void toggleAlertsOnly() {
    alertsOnly.value = !alertsOnly.value;
  }

  void clearFilters() {
    if (!hasFiltersApplied) return;
    statusFilter.value = 'all';
    alertsOnly.value = false;
    monthFilter.value = null;
    filter.value = '';
    searchTerm.value = '';
    searchCtrl.clear();
  }

  void setYearFilter(int year) {
    if (yearFilter.value == year) return;
    yearFilter.value = year;
    final selectedMonth = monthFilter.value;
    if (selectedMonth != null) {
      monthFilter.value = DateTime(year, selectedMonth.month);
    }
  }

  void setMonthFilter(DateTime? month) {
    if (month == null) {
      monthFilter.value = null;
      return;
    }
    final normalized = DateTime(yearFilter.value, month.month);
    final current = monthFilter.value;
    if (current != null &&
        current.year == normalized.year &&
        current.month == normalized.month) {
      monthFilter.value = null;
    } else {
      monthFilter.value = normalized;
    }
  }

  PurchasePrefillData? consumePrefillDraft() {
    final data = _pendingPrefill;
    _pendingPrefill = null;
    return data;
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  void _replaceItem(PurchaseModel updated) {
    final idx = items.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      final previousStatus = items[idx].status.toLowerCase();
      items[idx] = updated;
      items.refresh();
      if (previousStatus != 'received' &&
          updated.status.toLowerCase() == 'received') {
        unawaited(
          _refreshInventoryAfterReceive(
            purchaseId: updated.id,
            items: updated.items,
          ),
        );
      }
    }
  }

  void _handleNotification(PurchaseModel model, {String? fallback}) {
    final text = (model.lastNotification ?? fallback)?.trim();
    if (text == null || text.isEmpty) return;
    Get.showSnackbar(
      GetSnackBar(
        messageText: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.blueGrey.shade800,
      ),
    );
  }
}



