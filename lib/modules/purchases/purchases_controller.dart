import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/purchase_model.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
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

  @override
  Future<void> onInit() async {
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
    } finally {
      isLoading(false);
    }
  }

  Future<void> _populateSupplierNames() async {
    try {
      final svc = Get.find<SuppliersService>();
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
  }) async {
    isLoading(true);
    try {
      final p = await _service.create(
        supplierId: supplierId,
        items: items,
        status: status,
        freight: freight,
        notes: notes,
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
}
