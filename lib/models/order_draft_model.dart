import 'dart:convert';

import 'package:air_sync/models/order_model.dart';

class OrderDraftMaterial {
  OrderDraftMaterial({
    this.itemId,
    this.itemName,
    this.description,
    this.qty,
    this.unitPrice,
  });

  final String? itemId;
  final String? itemName;
  final String? description;
  final double? qty;
  final double? unitPrice;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'itemName': itemName,
        'description': description,
        'qty': qty,
        'unitPrice': unitPrice,
      };

  factory OrderDraftMaterial.fromMap(Map<String, dynamic> map) {
    return OrderDraftMaterial(
      itemId: map['itemId'] as String?,
      itemName: map['itemName'] as String?,
      description: map['description'] as String?,
      qty: map['qty'] is num ? (map['qty'] as num).toDouble() : null,
      unitPrice:
          map['unitPrice'] is num ? (map['unitPrice'] as num).toDouble() : null,
    );
  }
}

class OrderDraftBillingItem {
  OrderDraftBillingItem({
    required this.type,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  final String type;
  final String name;
  final double qty;
  final double unitPrice;

  Map<String, dynamic> toMap() => {
        'type': type,
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
      };

  factory OrderDraftBillingItem.fromMap(Map<String, dynamic> map) {
    return OrderDraftBillingItem(
      type: (map['type'] ?? 'service').toString(),
      name: (map['name'] ?? '').toString(),
      qty: map['qty'] is num ? (map['qty'] as num).toDouble() : 0,
      unitPrice:
          map['unitPrice'] is num ? (map['unitPrice'] as num).toDouble() : 0,
    );
  }

  OrderBillingItem toBillingItem() => OrderBillingItem(
        type: type,
        name: name,
        qty: qty,
        unitPrice: unitPrice,
      );
}

class OrderDraftModel {
  OrderDraftModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.locationId,
    this.equipmentId,
    this.clientName,
    this.locationLabel,
    this.equipmentLabel,
    this.scheduledAt,
    this.technicianIds = const [],
    this.checklist = const [],
    this.materials = const [],
    this.billingItems = const [],
    this.billingDiscount = 0,
    this.notes,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? clientId;
  final String? locationId;
  final String? equipmentId;
  final String? clientName;
  final String? locationLabel;
  final String? equipmentLabel;
  final DateTime? scheduledAt;
  final List<String> technicianIds;
  final List<String> checklist;
  final List<OrderDraftMaterial> materials;
  final List<OrderDraftBillingItem> billingItems;
  final num billingDiscount;
  final String? notes;

  static String generateId() =>
      'draft:${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'clientId': clientId,
        'locationId': locationId,
        'equipmentId': equipmentId,
        'clientName': clientName,
        'locationLabel': locationLabel,
        'equipmentLabel': equipmentLabel,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'technicianIds': technicianIds,
        'checklist': checklist,
        'materials': materials.map((m) => m.toMap()).toList(),
        'billingItems': billingItems.map((b) => b.toMap()).toList(),
        'billingDiscount': billingDiscount,
        'notes': notes,
      };

  String toJson() => jsonEncode(toMap());

  factory OrderDraftModel.fromMap(Map<String, dynamic> map) {
    return OrderDraftModel(
      id: map['id']?.toString() ?? generateId(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      clientId: map['clientId'] as String?,
      locationId: map['locationId'] as String?,
      equipmentId: map['equipmentId'] as String?,
      clientName: map['clientName'] as String?,
      locationLabel: map['locationLabel'] as String?,
      equipmentLabel: map['equipmentLabel'] as String?,
      scheduledAt: map['scheduledAt'] == null
          ? null
          : DateTime.tryParse(map['scheduledAt'].toString()),
      technicianIds: _list(map['technicianIds']).map((e) => e.toString()).toList(),
      checklist: _list(map['checklist']).map((e) => e.toString()).toList(),
      materials: _list(map['materials'])
          .whereType<Map>()
          .map((e) => OrderDraftMaterial.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      billingItems: _list(map['billingItems'])
          .whereType<Map>()
          .map(
            (e) => OrderDraftBillingItem.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      billingDiscount: map['billingDiscount'] is num
          ? map['billingDiscount'] as num
          : 0,
      notes: map['notes'] as String?,
    );
  }

  factory OrderDraftModel.fromJson(String source) =>
      OrderDraftModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  OrderModel toOrderModel() {
    final billingItemsList = billingItems.map((e) => e.toBillingItem()).toList();
    final subtotal =
        billingItemsList.fold<num>(0, (sum, item) => sum + item.lineTotal);
    final billing = OrderBilling(
      items: billingItemsList,
      subtotal: subtotal,
      discount: billingDiscount,
      total: subtotal - billingDiscount,
      status: 'pending',
    );
    final materialsList = materials
        .map(
          (m) => OrderMaterialItem(
            itemId: (m.itemId ?? '').isEmpty ? 'draft_item' : m.itemId!,
            qty: m.qty ?? 0,
            reserved: false,
            deductedAt: null,
            itemName: m.itemName,
            description: m.description ?? m.itemName,
            unitPrice: m.unitPrice,
          ),
        )
        .toList();
    return OrderModel(
      id: id,
      clientId: clientId ?? '',
      locationId: locationId ?? '',
      equipmentId: equipmentId,
      status: 'draft',
      scheduledAt: scheduledAt,
      startedAt: null,
      finishedAt: null,
      technicianIds: technicianIds,
      checklist: checklist.map((item) => OrderChecklistItem(item: item)).toList(),
      materials: materialsList,
      billing: billing,
      timesheet: OrderTimesheet.empty(),
      photoUrls: const [],
      customerSignatureUrl: null,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      audit: OrderAudit.empty(),
      clientName: clientName,
      locationLabel: locationLabel,
      equipmentLabel: equipmentLabel,
    );
  }

  factory OrderDraftModel.fromOrder(OrderModel source) {
    final now = DateTime.now();
    return OrderDraftModel(
      id: generateId(),
      createdAt: now,
      updatedAt: now,
      clientId: source.clientId.isEmpty ? null : source.clientId,
      locationId: source.locationId.isEmpty ? null : source.locationId,
      equipmentId: source.equipmentId,
      clientName: source.clientName,
      locationLabel: source.locationLabel,
      equipmentLabel: source.equipmentLabel,
      scheduledAt: null,
      technicianIds: List<String>.from(source.technicianIds),
      checklist: source.checklist.map((item) => item.item).toList(),
      materials: source.materials
          .map(
            (item) => OrderDraftMaterial(
              itemId: item.itemId.isEmpty ? null : item.itemId,
              itemName: item.itemName,
              description: item.description ?? item.itemName,
              qty: item.qty.toDouble(),
              unitPrice: item.unitPrice,
            ),
          )
          .toList(),
      billingItems: source.billing.items
          .map(
            (item) => OrderDraftBillingItem(
              type: item.type,
              name: item.name,
              qty: item.qty.toDouble(),
              unitPrice: item.unitPrice.toDouble(),
            ),
          )
          .toList(),
      billingDiscount: source.billing.discount,
      notes: source.notes,
    );
  }
}

List<dynamic> _list(dynamic value) {
  if (value is List) return value;
  if (value == null) return const [];
  return const [];
}
