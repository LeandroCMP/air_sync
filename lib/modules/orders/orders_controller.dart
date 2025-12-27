import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/order_draft_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/modules/orders/order_create_bindings.dart';
import 'package:air_sync/modules/orders/order_create_page.dart';
import 'package:air_sync/modules/orders/order_create_result.dart';
import 'package:air_sync/modules/orders/order_booking_conflict.dart';
import 'package:air_sync/services/orders/order_draft_storage.dart';
import 'package:air_sync/services/orders/order_label_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersController extends GetxController with LoaderMixin, MessagesMixin {
  OrdersController({
    required OrdersService service,
    required OrderLabelService labelService,
    required OrderDraftStorage draftStorage,
  }) : _service = service,
       _labelService = labelService,
       _draftStorage = draftStorage;

  final OrdersService _service;
  final OrderLabelService _labelService;
  final OrderDraftStorage _draftStorage;
  int _activeLoads = 0;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> visibleOrders = <OrderModel>[].obs;

  /// '', 'scheduled', 'in_progress', 'done', 'canceled'
  final RxString status = ''.obs;

  /// 'today' | 'week' | 'month' | 'all'
  final RxString period = 'today'.obs;

  /// Busca local (cliente, local, equipamento)
  final RxString searchText = ''.obs;

  static const _kPrefPeriod = 'orders.period';
  static const _kPrefStatus = 'orders.status';
  static const _kPrefSearch = 'orders.search';

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    _restoreFilters();

    everAll([period, status], (_) => refreshList());
    ever<List<OrderModel>>(orders, (_) => _recomputeVisible());
    ever<String>(searchText, (_) => _recomputeVisible());
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await refreshList();
    super.onReady();
  }

  @override
  void onClose() {
    _persistFilters();
    super.onClose();
  }

  Future<void> refreshList() async {
    _activeLoads++;
    if (_activeLoads == 1) {
      isLoading(true);
    }
    try {
      final now = DateTime.now();
      DateTime? from;
      DateTime? to;
      final statusFilter = status.value;
      final filteringDrafts = statusFilter == 'draft';

      if (filteringDrafts) {
        final drafts = await _draftStorage.getAll();
        orders.assignAll(drafts.map((draft) => draft.toOrderModel()).toList());
        _recomputeVisible();
        return;
      }

      switch (period.value) {
        case 'today':
          from = DateTime(now.year, now.month, now.day);
          to = from.add(const Duration(days: 1));
          break;
        case 'week':
          final weekday = now.weekday;
          from = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: weekday - 1));
          to = from.add(const Duration(days: 7));
          break;
        case 'month':
          from = DateTime(now.year, now.month, 1);
          to = DateTime(now.year, now.month + 1, 1);
          break;
        case 'all':
          from = null;
          to = null;
          break;
        default:
          from = DateTime(now.year, now.month, 1);
          to = DateTime(now.year, now.month + 1, 1);
      }

      final list = await _service.list(
        from: from,
        to: to,
        status: statusFilter.isEmpty ? null : statusFilter,
      );

      final enriched = await _labelService.enrichAll(list);
      orders.assignAll(enriched.where((order) => !order.isDraft).toList());
      _recomputeVisible();
    } catch (e) {
      message(
        MessageModel.error(title: 'Erro', message: _apiError(e, 'Falha ao carregar ordens.')),
      );
    } finally {
      _activeLoads = (_activeLoads - 1).clamp(0, 1 << 30).toInt();
      if (_activeLoads == 0) {
        isLoading(false);
      }
    }
  }

  void setSearch(String value) => searchText.value = value;

  void clearFilters() {
    status.value = '';
    period.value = 'all';
    searchText.value = '';
    _persistFilters();
    refreshList();
  }

  void _recomputeVisible() {
    final query = searchText.value.trim().toLowerCase();
    if (query.isEmpty) {
      visibleOrders.assignAll(orders);
      return;
    }

    final filtered =
        orders.where((order) {
          final haystack =
              [
                order.clientName,
                order.locationLabel,
                order.equipmentLabel,
                order.notes,
              ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(query);
        }).toList();

    visibleOrders.assignAll(filtered);
  }

  Future<void> _restoreFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPeriod = prefs.getString(_kPrefPeriod);
    final savedStatus = prefs.getString(_kPrefStatus);
    final savedSearch = prefs.getString(_kPrefSearch);

    if (savedPeriod != null && savedPeriod.isNotEmpty) {
      period.value = savedPeriod;
    }
    if (savedStatus != null) {
      status.value = savedStatus;
    }
    if (savedSearch != null) {
      searchText.value = savedSearch;
    }
  }

  Future<void> _persistFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefPeriod, period.value);
    await prefs.setString(_kPrefStatus, status.value);
    await prefs.setString(_kPrefSearch, searchText.value);
  }

  Future<void> openCreate() async {
    final result = await Get.to<dynamic>(
      () => const OrderCreatePage(),
      binding: OrderCreateBindings(),
    );
    if (result is OrderModel) {
      final created = await _labelService.enrich(result);
      upsertOrder(created);
      Get.snackbar('OS criada', 'A ordem foi cadastrada com sucesso.');
    } else if (result == OrderCreateResult.draftDeleted) {
      Get.snackbar(
        'Rascunho',
        'Rascunho excluído.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> openDraft(String draftId) async {
    final draft = await _draftStorage.getById(draftId);
    if (draft == null) {
      message(
        MessageModel.error(
          title: 'Rascunho',
          message: 'Não foi possível localizar esse rascunho.',
        ),
      );
      return;
    }
    final result = await Get.to<dynamic>(
      () => const OrderCreatePage(),
      binding: OrderCreateBindings(initialDraft: draft),
    );
    if (result is OrderModel) {
      upsertOrder(await _labelService.enrich(result));
      Get.snackbar('OS criada', 'Rascunho enviado para a API.');
    } else if (result == OrderCreateResult.draftDeleted) {
      Get.snackbar(
        'Rascunho',
        'Rascunho excluído.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> notifyDraftsChanged() async {
    if (status.value == 'draft') {
      await refreshList();
    }
  }

  Future<void> duplicateOrder(OrderModel source, {bool asDraft = false}) async {
    if (asDraft) {
      final draft = OrderDraftModel.fromOrder(source);
      await _draftStorage.save(draft);
      await notifyDraftsChanged();
      message(
        MessageModel.success(
          title: 'Rascunho',
          message: 'Rascunho criado a partir da OS ${source.id}.',
        ),
      );
      return;
    }
    try {
      final checklistInputs =
          source.checklist
              .map(
                (item) => OrderChecklistInput(
                  item: item.item,
                  done: asDraft ? false : item.done,
                  note: item.note,
                ),
              )
              .toList();
      final materialInputs =
          source.materials
              .where((m) => m.itemId.isNotEmpty)
              .map(
        (m) => OrderMaterialInput(
          itemId: m.itemId,
          qty: m.qty,
          itemName:
              (m.itemName ?? '').trim().isEmpty
                  ? null
                  : m.itemName!.trim(),
          description:
              (m.description ?? m.itemName)?.trim().isEmpty == true
                  ? null
                  : (m.description ?? m.itemName)!.trim(),
          unitPrice: m.unitPrice?.toDouble(),
          unitCost: m.unitCost,
        ),
      )
      .toList();
      final billingInputs =
          source.billing.items
              .map(
                (item) => OrderBillingItemInput(
                  type: item.type,
                  name: item.name,
                  qty: item.qty,
                  unitPrice: item.unitPrice,
                ),
              )
              .toList();
      final notes =
          asDraft
              ? '[RASCUNHO] ${(source.notes ?? '').trim()}'.trim()
              : source.notes;
      final duplicated = await _service.create(
        clientId: source.clientId,
        locationId: source.locationId,
        equipmentId: source.equipmentId,
        status: asDraft ? 'draft' : 'scheduled',
        scheduledAt: asDraft ? null : source.scheduledAt,
        technicianIds: source.technicianIds,
        notes: notes,
        checklist: checklistInputs,
        materials: materialInputs,
        billingItems: billingInputs,
        billingDiscount: source.billing.discount,
      );
      final enriched = await _labelService.enrich(duplicated);
      upsertOrder(enriched);
      message(
        MessageModel.success(
          title: 'OS duplicada',
          message:
              asDraft
                  ? 'Rascunho criado a partir da OS ${source.id}.'
                  : 'Nova OS criada a partir da ${source.id}.',
        ),
      );
    } on DioException catch (e) {
      final conflict = parseOrderBookingConflict(e);
      if (conflict != null) {
        final techHint =
            source.technicianIds.isEmpty
                ? ''
                : ' Tecnicos: ${source.technicianIds.join(', ')}.';
        message(
          MessageModel.error(
            title: 'Conflito de agenda',
            message:
                'Este tecnico ja tem OS nesse horario.$techHint Ajuste o horario ou escolha outra equipe antes de duplicar.',
          ),
        );
      } else {
        message(
          MessageModel.error(
            title: 'Duplicacao',
            message: 'Nao foi possivel duplicar a OS.',
          ),
        );
      }
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Duplicacao',
          message: 'Nao foi possivel duplicar a OS.',
        ),
      );
    }
  }
  void upsertOrder(OrderModel updated) {
    if (status.value.isNotEmpty && updated.status != status.value) {
      orders.removeWhere((order) => order.id == updated.id);
      _recomputeVisible();
      return;
    }
    final index = orders.indexWhere((order) => order.id == updated.id);
    if (index >= 0) {
      orders[index] = updated;
    } else {
      orders.insert(0, updated);
    }
    _recomputeVisible();
  }

  void removeOrder(String id) {
    final initial = orders.length;
    orders.removeWhere((order) => order.id == id);
    if (orders.length != initial) {
      _recomputeVisible();
    } else {
      visibleOrders.removeWhere((order) => order.id == id);
    }
  }

  String _apiError(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['message'] is String && (nested['message'] as String).trim().isNotEmpty) {
        return (nested['message'] as String).trim();
      }
      if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
        return (data['message'] as String).trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if ((error.message ?? '').isNotEmpty) return error.message!;
  } else if (error is Exception) {
    final text = error.toString();
    if (text.trim().isNotEmpty) return text;
  }
  return fallback;
}

}

