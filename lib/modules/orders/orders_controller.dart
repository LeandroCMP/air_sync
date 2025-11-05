import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/modules/orders/order_create_bindings.dart';
import 'package:air_sync/modules/orders/order_create_page.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersController extends GetxController with LoaderMixin, MessagesMixin {
  OrdersController({required OrdersService service}) : _service = service;

  final OrdersService _service;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> visibleOrders = <OrderModel>[].obs;

  /// '', 'scheduled', 'in_progress', 'done', 'canceled'
  final RxString status = ''.obs;

  /// 'today' | 'week' | 'month'
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
    everAll([orders, searchText], (_) => _recomputeVisible());
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
    isLoading(true);
    try {
      final now = DateTime.now();
      late DateTime from;
      late DateTime to;

      if (period.value == 'today') {
        from = DateTime(now.year, now.month, now.day);
        to = from.add(const Duration(days: 1));
      } else if (period.value == 'week') {
        final weekday = now.weekday;
        from = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        to = from.add(const Duration(days: 7));
      } else {
        from = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        to = nextMonth;
      }

      final list = await _service.list(
        from: from,
        to: to,
        status: status.value.isEmpty ? null : status.value,
      );

      orders.assignAll(list);
    } catch (_) {
      message(
        MessageModel.error(title: 'Erro', message: 'Falha ao carregar ordens.'),
      );
    } finally {
      isLoading(false);
    }
  }

  void setSearch(String value) => searchText.value = value;

  void clearFilters() {
    status.value = '';
    period.value = 'today';
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
    final created = await Get.to<OrderModel?>(
      () => const OrderCreatePage(),
      binding: OrderCreateBindings(),
    );
    if (created != null) {
      orders.insert(0, created);
      _recomputeVisible();
    }
  }
}
