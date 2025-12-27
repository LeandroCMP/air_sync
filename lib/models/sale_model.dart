import 'package:intl/intl.dart';

class SaleItemModel {
  const SaleItemModel({
    required this.type,
    required this.name,
    this.quantity = 1,
    this.unitPrice,
    this.total,
    this.inventoryItemId,
    this.requiresInstallation = false,
  });

  final String type;
  final String name;
  final double quantity;
  final double? unitPrice;
  final double? total;
  final String? inventoryItemId;
  final bool requiresInstallation;

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'sim';
      }
      return false;
    }

    String normalizeType(dynamic raw) {
      final value = (raw ?? '').toString().toLowerCase();
      if (value == 'product' || value == 'service') {
        return value;
      }
      return 'service';
    }

    String? parseInventoryId(dynamic source) {
      if (source == null) return null;
      if (source is String) return source;
      if (source is Map && source['id'] != null) {
        return source['id'].toString();
      }
      return null;
    }

    return SaleItemModel(
      type: normalizeType(map['type']),
      name: (map['name'] ?? map['description'] ?? '').toString(),
      quantity: parseDouble(map['qty'] ?? map['quantity']) ?? 1,
      unitPrice: parseDouble(map['unitPrice'] ?? map['unit_price']),
      total: parseDouble(map['total']),
      inventoryItemId: parseInventoryId(map['inventoryItemId'] ?? map['inventoryItem']),
      requiresInstallation: parseBool(map['requiresInstallation']),
    );
  }

  Map<String, dynamic> toPayload() {
    final normalizedType = (type.isEmpty ? 'service' : type).toLowerCase();
    final payload = <String, dynamic>{
      'type': (normalizedType == 'product' ? 'product' : 'service'),
      'name': name.trim(),
      'qty': quantity,
    };
    if (unitPrice != null) payload['unitPrice'] = unitPrice;
    if ((inventoryItemId ?? '').isNotEmpty) payload['inventoryItemId'] = inventoryItemId;
    if (requiresInstallation) payload['requiresInstallation'] = true;
    return payload;
  }
}

class SaleHistoryEntry {
  const SaleHistoryEntry({
    required this.status,
    this.message,
    this.userName,
    this.createdAt,
  });

  final String status;
  final String? message;
  final String? userName;
  final DateTime? createdAt;

  factory SaleHistoryEntry.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return SaleHistoryEntry(
      status: (map['status'] ?? map['type'] ?? '').toString(),
      message: map['message']?.toString(),
      userName: map['user']?.toString() ?? map['createdBy']?.toString(),
      createdAt: parseDate(map['createdAt'] ?? map['date']),
    );
  }
}

class SaleModel {
  const SaleModel({
    required this.id,
    required this.status,
    this.title,
    this.customerName,
    this.clientId,
    this.clientName,
    this.locationId,
    this.locationName,
    this.total,
    this.expectedAt,
    this.createdAt,
    this.updatedAt,
    this.discount,
    this.moveRequest,
    this.notes,
    this.linkedOrderId,
    this.linkedOrderStatus,
    this.autoCreateOrder = false,
    this.items = const [],
    this.history = const [],
  });

  final String id;
  final String status;
  final String? title;
  final String? customerName;
  final String? clientId;
  final String? clientName;
  final String? locationId;
  final String? locationName;
  final double? total;
  final DateTime? expectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? discount;
  final Map<String, dynamic>? moveRequest;
  final String? notes;
  final String? linkedOrderId;
  final String? linkedOrderStatus;
  final bool autoCreateOrder;
  final List<SaleItemModel> items;
  final List<SaleHistoryEntry> history;

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'sim';
      }
      return false;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    final items = ((map['items'] ?? map['lines']) as List?)
            ?.whereType<Map>()
            .map(
              (e) => SaleItemModel.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList() ??
        const <SaleItemModel>[];

    final history = ((map['history'] ?? map['timeline']) as List?)
            ?.whereType<Map>()
            .map(
              (e) => SaleHistoryEntry.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList() ??
        const <SaleHistoryEntry>[];

    final totals = map['totals'] is Map ? Map<String, dynamic>.from(map['totals']) : null;
    final resolvedClientName =
        (map['clientName'] ?? map['customerName'] ?? '').toString().trim();

    return SaleModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      status: (map['status'] ?? 'draft').toString(),
      title: map['title']?.toString() ?? map['name']?.toString(),
      customerName: resolvedClientName.isEmpty ? null : resolvedClientName,
      clientId: map['clientId']?.toString(),
      clientName: resolvedClientName.isEmpty ? null : resolvedClientName,
      locationId: map['locationId']?.toString(),
      locationName: map['locationName']?.toString() ??
          (map['location'] is Map ? (map['location']['label'] ?? '').toString() : null),
      total: parseDouble(map['total'] ?? totals?['total']),
      expectedAt: parseDate(map['expectedAt'] ?? map['dueDate']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      discount: parseDouble(map['discount'] ?? totals?['discount']),
      moveRequest: map['moveRequest'] is Map
          ? Map<String, dynamic>.from(map['moveRequest'])
          : null,
      notes: map['notes']?.toString(),
      linkedOrderId: map['linkedOrderId']?.toString() ?? map['orderId']?.toString(),
      linkedOrderStatus: map['linkedOrderStatus']?.toString(),
      autoCreateOrder: parseBool(map['autoCreateOrder'] ?? map['auto_create_order']),
      items: items,
      history: history,
    );
  }

  bool get canApprove => status == 'draft' || status == 'pending';
  bool get canFulfill => status == 'approved';
  bool get canCancel => status != 'cancelled' && status != 'fulfilled';
  bool get canEdit => status == 'draft' || status == 'quoted';

  String get displayTitle {
    if ((title ?? '').isNotEmpty) return title!;
    if ((clientName ?? customerName ?? '').isNotEmpty) {
      final name = clientName ?? customerName;
      return 'Venda para $name';
    }
    return 'Venda $id';
  }

  String get formattedTotal {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(total ?? 0);
  }
}
