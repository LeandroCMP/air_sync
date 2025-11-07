import 'package:air_sync/application/core/errors/client_failure.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/models/inventory_model.dart';
import 'package:air_sync/models/order_model.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';
import 'package:air_sync/services/locations/locations_service.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';

class OrderLabelService {
  OrderLabelService({
    required ClientService clientService,
    required LocationsService locationsService,
    required EquipmentsService equipmentsService,
    required InventoryService inventoryService,
  }) : _clientService = clientService,
       _locationsService = locationsService,
       _equipmentsService = equipmentsService,
       _inventoryService = inventoryService;

  final ClientService _clientService;
  final LocationsService _locationsService;
  final EquipmentsService _equipmentsService;
  final InventoryService _inventoryService;

  final Map<String, ClientModel> _clientCache = {};
  final Map<String, Map<String, LocationModel>> _locationsCache = {};
  final Map<String, Map<String, EquipmentModel>> _equipmentCache = {};
  final Map<String, InventoryItemModel> _inventoryCache = {};
  final Set<String> _missingClients = <String>{};

  Future<List<OrderModel>> enrichAll(Iterable<OrderModel> source) async {
    final result = <OrderModel>[];
    for (final order in source) {
      try {
        result.add(await enrich(order));
      } catch (_) {
        result.add(order);
      }
    }
    return result;
  }

  Future<OrderModel> enrich(OrderModel order) async {
    var clientName = _trim(order.clientName);
    var locationLabel = _trim(order.locationLabel);
    var equipmentLabel = _trim(order.equipmentLabel);
    final materials = <OrderMaterialItem>[];

    if (clientName == null || clientName.isEmpty) {
      clientName = await _resolveClientName(order.clientId) ?? clientName;
    }
    if ((locationLabel == null || locationLabel.isEmpty) &&
        order.locationId.isNotEmpty) {
      locationLabel =
          await _resolveLocationLabel(
            clientId: order.clientId,
            locationId: order.locationId,
          ) ??
          locationLabel;
    }
    if ((equipmentLabel == null || equipmentLabel.isEmpty) &&
        order.equipmentId != null &&
        order.equipmentId!.isNotEmpty) {
      equipmentLabel =
          await _resolveEquipmentLabel(
            clientId: order.clientId,
            locationId: order.locationId,
            equipmentId: order.equipmentId!,
          ) ??
          equipmentLabel;
    }

    for (final material in order.materials) {
      final resolved = await _resolveInventoryItem(material.itemId);
      if (resolved != null) {
        final description = resolved.description.trim();
        final sku = resolved.sku.trim();
        final preferredName =
            description.isNotEmpty
                ? description
                : (sku.isNotEmpty ? sku : material.itemName ?? material.itemId);
        materials.add(
          material.copyWith(
            itemName: preferredName,
            description: preferredName,
            unitPrice: resolved.sellPrice ?? material.unitPrice,
          ),
        );
      } else {
        final fallbackName =
            (material.itemName ?? '').trim().isNotEmpty
                ? material.itemName!.trim()
                : 'Item ${material.itemId}';
        materials.add(
          material.copyWith(
            itemName: fallbackName,
            description: fallbackName,
          ),
        );
      }
    }

    return order.copyWith(
      clientName: clientName ?? order.clientName,
      locationLabel: locationLabel ?? order.locationLabel,
      equipmentLabel: equipmentLabel ?? order.equipmentLabel,
      materials: materials.isEmpty ? order.materials : materials,
    );
  }

  Future<String?> _resolveClientName(String clientId) async {
    final id = clientId.trim();
    if (id.isEmpty) return null;
    if (_missingClients.contains(id)) return 'Cliente nao informado';

    final cached = _clientCache[id];
    if (cached != null) return _trim(cached.name);
    try {
      final client = await _clientService.getById(id);
      _clientCache[id] = client;
      return _trim(client.name);
    } catch (error) {
      if (error is ClientFailure &&
          error.type == ClientFailureType.validationError) {
        _missingClients.add(id);
        return 'Cliente nao informado';
      }
      return null;
    }
  }

  Future<String?> _resolveLocationLabel({
    required String clientId,
    required String locationId,
  }) async {
    final trimmedClient = clientId.trim();
    final trimmedLocation = locationId.trim();
    if (trimmedClient.isEmpty || trimmedLocation.isEmpty) return null;
    if (_missingClients.contains(trimmedClient)) return null;

    final clientLocations = _locationsCache.putIfAbsent(
      trimmedClient,
      () => <String, LocationModel>{},
    );
    if (!clientLocations.containsKey(trimmedLocation)) {
      try {
        final fetched = await _locationsService.listByClient(trimmedClient);
        for (final location in fetched) {
          clientLocations[location.id] = location;
        }
      } catch (_) {
        // ignore
      }
    }

    final location = clientLocations[trimmedLocation];
    if (location == null) return null;
    return _formatLocation(location);
  }

  Future<String?> _resolveEquipmentLabel({
    required String clientId,
    required String locationId,
    required String equipmentId,
  }) async {
    final trimmedClient = clientId.trim();
    final trimmedEquipment = equipmentId.trim();
    final trimmedLocation = locationId.trim();
    if (trimmedClient.isEmpty || trimmedEquipment.isEmpty) return null;
    if (_missingClients.contains(trimmedClient)) return null;

    final clientEquipments = _equipmentCache.putIfAbsent(
      trimmedClient,
      () => <String, EquipmentModel>{},
    );
    if (!clientEquipments.containsKey(trimmedEquipment)) {
      try {
        final fetched = await _equipmentsService.listBy(
          trimmedClient,
          locationId: trimmedLocation.isEmpty ? null : trimmedLocation,
        );
        for (final equipment in fetched) {
          clientEquipments[equipment.id] = equipment;
        }
      } catch (_) {
        // ignore
      }
    }

    final equipment = clientEquipments[trimmedEquipment];
    if (equipment == null) return null;
    return _formatEquipment(equipment);
  }

  String? _trim(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatLocation(LocationModel location) {
    final parts = <String>[];
    final label = location.label.trim();
    if (label.isNotEmpty) parts.add(label);
    final address = location.addressLine.trim();
    if (address.isNotEmpty) parts.add(address);
    final cityState = location.cityState.trim();
    if (cityState.isNotEmpty) parts.add(cityState);
    if (parts.isEmpty) return 'Local ${location.id}';
    return parts.join(' - ');
  }

  String _formatEquipment(EquipmentModel equipment) {
    final parts = <String>[];
    final room = (equipment.room ?? '').trim();
    if (room.isNotEmpty) parts.add(room);
    final brand = (equipment.brand ?? '').trim();
    if (brand.isNotEmpty) parts.add(brand);
    final model = (equipment.model ?? '').trim();
    if (model.isNotEmpty) parts.add(model);
    final type = (equipment.type ?? '').trim();
    if (type.isNotEmpty) parts.add(type);
    if (parts.isEmpty) return 'Equipamento ${equipment.id}';
    return parts.join(' - ');
  }

  Future<InventoryItemModel?> _resolveInventoryItem(String itemId) async {
    final cached = _inventoryCache[itemId];
    if (cached != null) return cached;
    try {
      final item = await _inventoryService.getItem(itemId);
      _inventoryCache[itemId] = item;
      return item;
    } catch (_) {
      return null;
    }
  }
}
