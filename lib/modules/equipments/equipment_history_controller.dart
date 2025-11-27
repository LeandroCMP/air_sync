import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/application/utils/pdf/equipment_report_pdf.dart';
import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/users/users_service.dart';

class EquipmentHistoryController extends GetxController
    with LoaderMixin, MessagesMixin {
  final EquipmentsService _service;
  final OrdersService? _ordersService;
  final UsersService? _usersService;
  EquipmentHistoryController({
    required EquipmentsService service,
    OrdersService? ordersService,
    UsersService? usersService,
  }) : _service = service,
       _ordersService = ordersService,
       _usersService = usersService;

  late final String equipmentId;
  EquipmentModel? equipment;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();
  final items = <Map<String, dynamic>>[].obs;
  List<CollaboratorModel>? _technicianCatalog;
  final Map<String, String> _technicianNameIndex = {};

  @override
  Future<void> onInit() async {
    loaderListener(isLoading);
    messageListener(message);
    final args = Get.arguments;
    if (args is Map) {
      equipmentId = (args['id'] ?? '').toString();
      final e = args['equipment'];
      if (e is EquipmentModel) equipment = e;
    } else if (args is String) {
      equipmentId = args;
    } else {
      equipmentId = args?.toString() ?? '';
    }
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
      final list = await _service.listHistory(equipmentId);
      final ordered = _orderHistory(list);
      final enriched = await _enrichWithOrderDetails(ordered);
      items.assignAll(enriched);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Histórico',
          message: 'Falha ao carregar histórico',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  // Apenas leitura; eventos vêm das OS e ações de equipamento.
  Future<void> exportPdf() async {
    isLoading(true);
    try {
      final hist =
          items
              .map(
                (e) => MaintenanceModel.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList();
      final eq = equipment; // ideal: passar o EquipmentModel via arguments
      if (eq == null) {
        message(
          MessageModel.error(
            title: 'Relatório',
            message: 'Dados do equipamento indisponíveis',
          ),
        );
        return;
      }

      final authApp = Get.find<AuthServiceApplication>();
      final user = authApp.user.value;
      final companyName = user?.name;
      final locationLabel = await _tryLocationLabel(eq.clientId, eq.locationId);

      final bytes = await buildEquipmentReportPdf(
        equipment: eq,
        history: hist,
        appName: 'AirSync',
        companyName: companyName,
        locationLabel: locationLabel,
        clientName: null,
        companyDocument: user?.cpfOrCnpj,
        companyEmail: user?.email,
        companyPhone: user?.phone,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'equipamento_${eq.id}.pdf',
      );
    } catch (_) {
      message(
        MessageModel.error(title: 'Relatório', message: 'Falha ao gerar PDF'),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<String?> _tryLocationLabel(String clientId, String locationId) async {
    try {
      final locs = await Get.find<LocationsService>().listByClient(clientId);
      for (final l in locs) {
        if (l.id == locationId) return l.label;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _orderHistory(List<Map<String, dynamic>> source) {
    DateTime? parse(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        if (value > 1e12) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      if (value is num) {
        final millis =
            value.abs() > 1e12
                ? value.toInt()
                : (value.toDouble() * 1000).round();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final list = List<Map<String, dynamic>>.from(source);
    list.sort((a, b) {
      final da = parse(
        a['at'] ?? a['date'] ?? a['createdAt'] ?? a['performedAt'],
      );
      final db = parse(
        b['at'] ?? b['date'] ?? b['createdAt'] ?? b['performedAt'],
      );
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  Future<List<Map<String, dynamic>>> _enrichWithOrderDetails(
    List<Map<String, dynamic>> source,
  ) async {
    if (_ordersService == null) return source;
    final result = <Map<String, dynamic>>[];
    for (final entry in source) {
      final orderId = (entry['orderId'] ?? entry['order'] ?? '').toString();
      if (orderId.isEmpty) {
        result.add(entry);
        continue;
      }
      try {
        final OrderModel order = await _ordersService.getById(orderId);
        final performedBy = await _resolveTechnicianNames(order.technicianIds);
        final services = _extractServices(order);
        final materials =
            order.materials
                .map(
                  (m) => {
                    'name':
                        (m.itemName ?? m.description ?? 'Item ${m.itemId}')
                            .trim(),
                    'qty': m.qty.toDouble(),
                    'unitPrice': (m.unitPrice ?? 0).toDouble(),
                  },
                )
                .toList();
        result.add({
          ...entry,
          'orderId': orderId,
          'orderStatus': order.status,
          'locationLabel': order.locationLabel ?? '',
          'performedBy': performedBy,
          'duration':
              order.timesheet.totalMinutes == null
                  ? ''
                  : '${order.timesheet.totalMinutes} min',
          'materials': materials,
          'billingTotal': (order.billing.total as num?)?.toDouble() ?? 0,
          'notes': entry['notes'] ?? order.notes ?? '',
          'services': services,
          'serviceSummary': services.isEmpty ? '' : services.join(', '),
        });
      } catch (_) {
        result.add(entry);
      }
    }
    return result;
  }

  Future<void> _warmTechnicianCatalog({CollaboratorRole? role}) async {
    final svc =
        _usersService ??
        (Get.isRegistered<UsersService>() ? Get.find<UsersService>() : null);
    if (svc == null) return;
    try {
      final fetched = await svc.list(role: role);
      if (fetched.isEmpty) return;
      final merged = <String, CollaboratorModel>{};
      if (_technicianCatalog != null) {
        for (final tech in _technicianCatalog!) {
          merged[tech.id] = tech;
        }
      }
      for (final tech in fetched) {
        merged[tech.id] = tech;
        _technicianNameIndex[tech.id.trim()] = tech.name;
      }
      _technicianCatalog = merged.values.toList();
    } catch (_) {
      // ignore failures
    }
  }

  Future<String> _resolveTechnicianNames(List<String> ids) async {
    if (ids.isEmpty) return '';
    final normalizedIds =
        ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    if (normalizedIds.isEmpty) return '';

    await _warmTechnicianCatalog(role: CollaboratorRole.tech);

    final missing =
        normalizedIds
            .where((id) => !_technicianNameIndex.containsKey(id))
            .toList();
    if (missing.isNotEmpty) {
      await _warmTechnicianCatalog();
    }

    final names =
        normalizedIds
            .map(
              (id) =>
                  _technicianNameIndex[id]?.trim().isNotEmpty == true
                      ? _technicianNameIndex[id]!.trim()
                      : id,
            )
            .where((value) => value.isNotEmpty)
            .toList();
    return names.join(', ');
  }

  List<String> _extractServices(OrderModel order) {
    final services = <String>[];
    for (final item in order.billing.items) {
      final label = item.name.trim();
      if (label.isEmpty) continue;
      if (item.type.toLowerCase() != 'service') continue;
      final qty = item.qty;
      if (qty == 0 || qty == 1) {
        services.add(label);
      } else {
        services.add('$label (${qty}x)');
      }
    }
    if (services.isNotEmpty) return services;
    final note = (order.notes ?? '').trim();
    if (note.isNotEmpty) return [note];
    return const [];
  }
}
