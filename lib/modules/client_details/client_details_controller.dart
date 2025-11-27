import 'package:air_sync/application/core/errors/client_failure.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/collaborator_models.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/orders/orders_service.dart';
import 'package:air_sync/services/users/users_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'equipment_pdf_preview_page.dart';

class ClientDetailsController extends GetxController
    with MessagesMixin, LoaderMixin {
  ClientDetailsController({
    required ClientService clientService,
    required LocationsService locationsService,
    required EquipmentsService equipmentsService,
    OrdersService? ordersService,
    UsersService? usersService,
  }) : _clientService = clientService,
       _locationsService = locationsService,
       _equipmentsService = equipmentsService,
       _ordersService = ordersService,
       _usersService = usersService,
       _cepClient = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 5),
           receiveTimeout: const Duration(seconds: 5),
         ),
       );

  final ClientService _clientService;
  final LocationsService _locationsService;
  final EquipmentsService _equipmentsService;
  final OrdersService? _ordersService;
  final UsersService? _usersService;
  final Dio _cepClient;

  final message = Rxn<MessageModel>();
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingLocations = false.obs;
  final isSavingLocation = false.obs;
  final isFetchingCep = false.obs;

  final deletingLocationIds = <String>{}.obs;
  final deletingEquipmentIds = <String>{}.obs;

  final Rxn<ClientModel> client = Rxn<ClientModel>();
  final locations = <LocationModel>[].obs;

  final locationEquipments = <String, List<EquipmentModel>>{}.obs;
  final equipmentLoading = <String, bool>{}.obs;
  final equipmentHistory = <String, List<Map<String, dynamic>>>{}.obs;
  final equipmentHistoryLoading = <String, bool>{}.obs;
  List<CollaboratorModel>? _technicianCatalog;
  final Map<String, String> _technicianNameIndex = {};

  late final String _clientId;
  String? _lastCepLookedUp;
  Map<String, String?> _lastCepData = {};

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  @override
  void onReady() {
    _initializeClient();
    super.onReady();
  }

  void _initializeClient() {
    final args = Get.arguments;
    if (args is ClientModel) {
      client.value = args;
      _clientId = args.id;
    } else if (args is Map && args['client'] is ClientModel) {
      final model = args['client'] as ClientModel;
      client.value = model;
      _clientId = model.id;
    } else if (args is Map && args['clientId'] is String) {
      _clientId = args['clientId'] as String;
    } else if (args is String) {
      _clientId = args;
    } else {
      throw ArgumentError('Parâmetros inválidos para detalhes do cliente');
    }

    if (_clientId.isEmpty) return;
    refreshClient();
  }

  Future<void> refreshClient() async {
    if (_clientId.isEmpty) return;
    isRefreshing(true);
    try {
      final data = await _clientService.getById(_clientId);
      client.value = data;
      await loadLocations();
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível carregar os detalhes do cliente.',
        ),
      );
    } finally {
      isRefreshing(false);
    }
  }

  Future<void> loadLocations() async {
    isLoadingLocations(true);
    try {
      final list = await _locationsService.listByClient(_clientId);
      locations.assignAll(list);
      locationEquipments.removeWhere(
        (key, _) => list.every((location) => location.id != key),
      );
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível carregar os endereços do cliente.',
        ),
      );
    } finally {
      isLoadingLocations(false);
    }
  }

  List<EquipmentModel> equipmentsFor(String locationId) {
    return List<EquipmentModel>.unmodifiable(
      locationEquipments[locationId] ?? const <EquipmentModel>[],
    );
  }

  bool isEquipmentLoading(String locationId) =>
      equipmentLoading[locationId] ?? false;

  bool isEquipmentHistoryLoading(String equipmentId) =>
      equipmentHistoryLoading[equipmentId] ?? false;

  List<Map<String, dynamic>> historyFor(String equipmentId) =>
      equipmentHistory[equipmentId] ?? const <Map<String, dynamic>>[];

  Future<void> loadEquipmentsForLocation(
    String locationId, {
    bool force = false,
  }) async {
    if (locationId.isEmpty) return;
    if (!force && locationEquipments.containsKey(locationId)) return;

    equipmentLoading[locationId] = true;
    equipmentLoading.refresh();
    try {
      final list = await _equipmentsService.listBy(
        _clientId,
        locationId: locationId,
      );
      locationEquipments[locationId] = list;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível carregar os equipamentos do endereço.',
        ),
      );
    } finally {
      equipmentLoading[locationId] = false;
      equipmentLoading.refresh();
    }
  }

  Future<bool> createLocation({
    required String reference,
    String? street,
    String? number,
    String? city,
    String? state,
    String? zip,
    String? notes,
  }) async {
    if (_clientId.isEmpty || isSavingLocation.value) return false;

    final trimmedReference = reference.trim();
    if (trimmedReference.isEmpty) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Informe uma referência para o endereço.',
        ),
      );
      return false;
    }

    final address = _buildAddressMap(
      street: street,
      number: number,
      city: city,
      state: state,
      zip: zip,
    );
    final sanitizedNotes = _sanitizeNotes(notes);

    isSavingLocation(true);
    try {
      final created = await _locationsService.create(
        clientId: _clientId,
        label: trimmedReference,
        address: address,
        notes: sanitizedNotes,
      );
      locations.insert(0, created);
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Endereço cadastrado com sucesso.',
        ),
      );
      return true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível cadastrar o endereço.',
        ),
      );
    } finally {
      isSavingLocation(false);
    }
    return false;
  }

  Future<bool> updateLocation({
    required LocationModel location,
    required String reference,
    String? street,
    String? number,
    String? city,
    String? state,
    String? zip,
    String? notes,
  }) async {
    if (_clientId.isEmpty || isSavingLocation.value) return false;

    final trimmedReference = reference.trim();
    if (trimmedReference.isEmpty) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Informe uma referência para o endereço.',
        ),
      );
      return false;
    }

    final addressChanges = _buildAddressMap(
      street: street,
      number: number,
      city: city,
      state: state,
      zip: zip,
      original: location,
      includeNulls: true,
    );
    final sanitizedNotes = _sanitizeNotes(notes);
    final currentNotes = _sanitizeNotes(location.notes);
    final includeNotes = sanitizedNotes != currentNotes;

    if (trimmedReference == location.label &&
        addressChanges.isEmpty &&
        sanitizedNotes == currentNotes) {
      return true;
    }

    isSavingLocation(true);
    try {
      final updated = await _locationsService.update(
        id: location.id,
        label: trimmedReference == location.label ? null : trimmedReference,
        address: addressChanges,
        notes: sanitizedNotes,
        includeNotes: includeNotes,
      );
      final index = locations.indexWhere((element) => element.id == updated.id);
      if (index >= 0) {
        locations[index] = updated;
      }
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Endereço atualizado com sucesso.',
        ),
      );
      return true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível atualizar o endereço.',
        ),
      );
    } finally {
      isSavingLocation(false);
    }
    return false;
  }

  Future<bool> deleteLocation(LocationModel location) async {
    if (deletingLocationIds.contains(location.id)) return false;
    deletingLocationIds.add(location.id);
    deletingLocationIds.refresh();
    try {
      await _locationsService.delete(location.id);
      locations.removeWhere((element) => element.id == location.id);
      locationEquipments.remove(location.id);
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Endereço removido com sucesso.',
        ),
      );
      return true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível remover o endereço.',
        ),
      );
    } finally {
      deletingLocationIds.remove(location.id);
      deletingLocationIds.refresh();
    }
    return false;
  }

  Future<bool> createEquipment({
    required LocationModel location,
    required String room,
    String? brand,
    String? model,
    String? type,
    int? btus,
    DateTime? installDate,
    String? serial,
    String? notes,
  }) async {
    if (isSavingLocation.value) return false;
    if (room.trim().isEmpty) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Informe o ambiente onde o equipamento está instalado.',
        ),
      );
      return false;
    }

    isSavingLocation(true);
    try {
      final created = await _equipmentsService.create(
        clientId: _clientId,
        locationId: location.id,
        room: room.trim(),
        brand: _sanitizeText(brand),
        model: _sanitizeText(model),
        type: _sanitizeText(type),
        btus: btus,
        installDate: installDate,
        serial: _sanitizeText(serial),
        notes: _sanitizeText(notes),
      );
      final list = List<EquipmentModel>.from(
        locationEquipments[location.id] ?? const <EquipmentModel>[],
      );
      list.insert(0, created);
      locationEquipments[location.id] = list;
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Equipamento cadastrado com sucesso.',
        ),
      );
      return true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível cadastrar o equipamento.',
        ),
      );
    } finally {
      isSavingLocation(false);
    }
    return false;
  }

  Future<bool> updateEquipment({
    required LocationModel location,
    required EquipmentModel equipment,
    required String room,
    String? brand,
    String? model,
    String? type,
    int? btus,
    DateTime? installDate,
    String? serial,
    String? notes,
  }) async {
    if (room.trim().isEmpty) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Informe o ambiente onde o equipamento está instalado.',
        ),
      );
      return false;
    }

    final sanitizedNotes = _sanitizeText(notes);
    final currentNotes = _sanitizeText(equipment.notes);
    final includeNotes = sanitizedNotes != currentNotes;

    isSavingLocation(true);
    try {
      final updated = await _equipmentsService.update(
        id: equipment.id,
        locationId: location.id == equipment.locationId ? null : location.id,
        brand: _valueIfChanged(brand, equipment.brand),
        model: _valueIfChanged(model, equipment.model),
        type: _valueIfChanged(type, equipment.type),
        btus: btus == equipment.btus ? null : btus,
        room: room.trim() == (equipment.room ?? '').trim() ? null : room.trim(),
        installDate: _dateIfChanged(installDate, equipment.installDate),
        serial: _valueIfChanged(serial, equipment.serial),
        notes: sanitizedNotes,
        includeNotes: includeNotes,
      );

      if (location.id != equipment.locationId) {
        final oldList = List<EquipmentModel>.from(
          locationEquipments[equipment.locationId] ?? const <EquipmentModel>[],
        );
        oldList.removeWhere((item) => item.id == equipment.id);
        locationEquipments[equipment.locationId] = oldList;

        final newList = List<EquipmentModel>.from(
          locationEquipments[location.id] ?? const <EquipmentModel>[],
        );
        newList.insert(0, updated);
        locationEquipments[location.id] = newList;
      } else {
        final list = List<EquipmentModel>.from(
          locationEquipments[location.id] ?? const <EquipmentModel>[],
        );
        final index = list.indexWhere((item) => item.id == updated.id);
        if (index >= 0) {
          list[index] = updated;
          locationEquipments[location.id] = list;
        }
      }

      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Equipamento atualizado com sucesso.',
        ),
      );
      return true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível atualizar o equipamento.',
        ),
      );
    } finally {
      isSavingLocation(false);
    }
    return false;
  }

  Future<bool> deleteEquipment(EquipmentModel equipment) async {
    if (deletingEquipmentIds.contains(equipment.id)) return false;
    deletingEquipmentIds.add(equipment.id);
    deletingEquipmentIds.refresh();
    try {
      await _equipmentsService.delete(equipment.id);
      final list = List<EquipmentModel>.from(
        locationEquipments[equipment.locationId] ?? const <EquipmentModel>[],
      );
      list.removeWhere((item) => item.id == equipment.id);
      locationEquipments[equipment.locationId] = list;
      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Equipamento removido com sucesso.',
        ),
      );
      return true;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível remover o equipamento.',
        ),
      );
    } finally {
      deletingEquipmentIds.remove(equipment.id);
      deletingEquipmentIds.refresh();
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> loadEquipmentHistory(
    String equipmentId,
  ) async {
    if (equipmentId.isEmpty) return const <Map<String, dynamic>>[];
    if (equipmentHistory.containsKey(equipmentId)) {
      return equipmentHistory[equipmentId]!;
    }

    equipmentHistoryLoading[equipmentId] = true;
    equipmentHistoryLoading.refresh();
    try {
      final raw = await _equipmentsService.listHistory(equipmentId);
      final ordered = _orderHistory(raw);
      final enriched = await _enrichHistoryEntries(ordered);
      equipmentHistory[equipmentId] = enriched;
      return enriched;
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível carregar o histórico do equipamento.',
        ),
      );
    } finally {
      equipmentHistoryLoading[equipmentId] = false;
      equipmentHistoryLoading.refresh();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> _enrichHistoryEntries(
    List<Map<String, dynamic>> source,
  ) async {
    final ordersService =
        _ordersService ??
        (Get.isRegistered<OrdersService>() ? Get.find<OrdersService>() : null);
    final result = <Map<String, dynamic>>[];
    for (final entry in source) {
      final normalized = Map<String, dynamic>.from(entry);
      final orderId = (normalized['orderId'] ?? '').toString();
      DateTime? parsedDate = _parseDate(
        normalized['at'] ??
            normalized['date'] ??
            normalized['performedAt'] ??
            normalized['createdAt'],
      );
      parsedDate ??= DateTime.now();
      normalized['at'] = parsedDate;
      if (orderId.isNotEmpty && ordersService != null) {
        try {
          final order = await ordersService.getById(orderId);
          final performedBy = await _resolveTechnicianNames(
            order.technicianIds,
          );
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
          normalized.addAll({
            'orderStatus': order.status,
            'locationLabel': order.locationLabel ?? '',
            'performedBy': performedBy,
            'duration':
                order.timesheet.totalMinutes == null
                    ? ''
                    : '${order.timesheet.totalMinutes} min',
            'materials': materials,
            'billingTotal': (order.billing.total as num?)?.toDouble() ?? 0,
            'notes': normalized['notes'] ?? order.notes ?? '',
            'services': services,
            'serviceSummary': services.isEmpty ? '' : services.join(', '),
          });
        } catch (_) {}
      }
      result.add(_withDescription(normalized));
    }
    return result;
  }

  Map<String, dynamic> _withDescription(Map<String, dynamic> entry) {
    final buffer = StringBuffer();
    final orderId = (entry['orderId'] ?? '').toString();
    final status = (entry['orderStatus'] ?? '').toString();
    final performedBy = (entry['performedBy'] ?? '').toString();
    final location = (entry['locationLabel'] ?? '').toString();
    final duration = (entry['duration'] ?? '').toString();
    final notes = (entry['notes'] ?? '').toString();
    final materials = entry['materials'] as List<dynamic>? ?? const [];
    final serviceSummary = (entry['serviceSummary'] ?? '').toString();
    if (orderId.isNotEmpty) {
      buffer.writeln(status.isEmpty ? 'OS $orderId' : 'OS $orderId ($status)');
    }
    if (performedBy.isNotEmpty) {
      buffer.writeln('Responsável: $performedBy');
    }
    if (location.isNotEmpty) {
      buffer.writeln('Local: $location');
    }
    if (duration.isNotEmpty) {
      buffer.writeln('Duração: $duration');
    }
    if (serviceSummary.isNotEmpty) {
      buffer.writeln('Serviço(s): $serviceSummary');
    }
    if (materials.isNotEmpty) {
      buffer.writeln(
        'Materiais: ${materials.map((m) => '${m['name']} ${m['qty']} un').join(', ')}',
      );
    }
    if (notes.isNotEmpty) {
      buffer.writeln(notes);
    }
    entry['description'] = buffer.toString().trim();
    return entry;
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

  List<Map<String, dynamic>> _orderHistory(List<Map<String, dynamic>> source) {
    final list = List<Map<String, dynamic>>.from(source);
    list.sort((a, b) {
      final da = _parseDate(
        a['at'] ?? a['date'] ?? a['createdAt'] ?? a['performedAt'],
      );
      final db = _parseDate(
        b['at'] ?? b['date'] ?? b['createdAt'] ?? b['performedAt'],
      );
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  DateTime? _parseDate(dynamic value) {
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

  Future<void> openEquipmentPdf(String id) async {
    final currentClient = client.value;
    if (currentClient == null) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Nao foi possivel gerar o relatorio do equipamento.',
        ),
      );
      return;
    }

    EquipmentModel? equipment;
    LocationModel? location;
    for (final loc in locations) {
      final list = locationEquipments[loc.id] ?? const <EquipmentModel>[];
      for (final item in list) {
        if (item.id == id) {
          equipment = item;
          location = loc;
          break;
        }
      }
      if (equipment != null) break;
    }

    if (equipment == null || location == null) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Equipamento nao encontrado para gerar o relatorio.',
        ),
      );
      return;
    }

    final history = await loadEquipmentHistory(id);
    final pdfHistory =
        history
            .map(
              (entry) =>
                  MaintenanceModel.fromMap(Map<String, dynamic>.from(entry)),
            )
            .toList();

    await Get.to(
      () => EquipmentPdfPreviewPage(
        equipment: equipment!,
        location: location!,
        client: currentClient,
        history: pdfHistory,
      ),
    );
  }

  Future<Map<String, String?>> lookupCep(String rawCep) async {
    final digits = rawCep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      _lastCepLookedUp = null;
      _lastCepData = {};
      return {};
    }

    if (_lastCepLookedUp == digits && _lastCepData.isNotEmpty) {
      return Map<String, String?>.from(_lastCepData);
    }

    isFetchingCep(true);
    try {
      final response = await _cepClient.get<Map<String, dynamic>>(
        'https://viacep.com.br/ws/$digits/json/',
      );
      final data = response.data;
      if (data == null || data['erro'] == true) {
        message(
          MessageModel.error(title: 'CEP', message: 'CEP não encontrado.'),
        );
        return {};
      }

      final result = <String, String?>{
        'street': data['logradouro']?.toString(),
        'city': data['localidade']?.toString(),
        'state': data['uf']?.toString(),
        'district': data['bairro']?.toString(),
      };
      _lastCepLookedUp = digits;
      _lastCepData = result;
      return Map<String, String?>.from(result);
    } catch (_) {
      message(
        MessageModel.error(
          title: 'CEP',
          message: 'Não foi possível consultar o CEP informado.',
        ),
      );
      return {};
    } finally {
      isFetchingCep(false);
    }
  }

  Future<void> openDialer(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível abrir o discador do telefone.',
        ),
      );
    }
  }

  Map<String, String?> _buildAddressMap({
    String? street,
    String? number,
    String? city,
    String? state,
    String? zip,
    LocationModel? original,
    bool includeNulls = false,
  }) {
    final result = <String, String?>{};

    String? normalize(
      String? value, {
      bool digitsOnly = false,
      bool uppercase = false,
    }) {
      if (value == null) return null;
      var trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (digitsOnly) {
        trimmed = trimmed.replaceAll(RegExp(r'\D'), '');
      }
      if (trimmed.isEmpty) return null;
      if (uppercase) {
        trimmed = trimmed.toUpperCase();
      }
      return trimmed;
    }

    String? normalizeOriginal(
      String? value, {
      bool digitsOnly = false,
      bool uppercase = false,
    }) {
      if (value == null) return null;
      var trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (digitsOnly) {
        trimmed = trimmed.replaceAll(RegExp(r'\D'), '');
      }
      if (trimmed.isEmpty) return null;
      if (uppercase) {
        trimmed = trimmed.toUpperCase();
      }
      return trimmed;
    }

    void handleField(
      String key,
      String? value,
      String? originalValue, {
      bool digitsOnly = false,
      bool uppercase = false,
    }) {
      final normalized = normalize(
        value,
        digitsOnly: digitsOnly,
        uppercase: uppercase,
      );
      final originalNormalized = normalizeOriginal(
        originalValue,
        digitsOnly: digitsOnly,
        uppercase: uppercase,
      );

      if (normalized != null) {
        if (normalized != originalNormalized) {
          result[key] = normalized;
        }
      } else if (includeNulls && originalNormalized != null) {
        result[key] = null;
      }
    }

    handleField('street', street, original?.street);
    handleField('number', number, original?.number);
    handleField('city', city, original?.city);
    handleField('state', state, original?.state, uppercase: true);
    handleField('zip', zip, original?.zip, digitsOnly: true);

    return result;
  }

  String? _sanitizeNotes(String? notes) {
    final trimmed = notes?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _sanitizeText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _valueIfChanged(String? nextValue, String? originalValue) {
    final normalizedNext = _sanitizeText(nextValue);
    final normalizedOriginal = _sanitizeText(originalValue);
    if (normalizedNext == null && normalizedOriginal == null) {
      return null;
    }
    if (normalizedNext == normalizedOriginal) {
      return null;
    }
    return normalizedNext;
  }

  DateTime? _dateIfChanged(DateTime? next, DateTime? original) {
    if (next == null && original == null) return null;
    if (next != null && original != null && next.isAtSameMomentAs(original)) {
      return null;
    }
    if (next == null && original != null) {
      return null;
    }
    return next;
  }
}
