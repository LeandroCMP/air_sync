class OrderModel {
  final String id;
  final String clientId;
  final String locationId;
  final String? equipmentId;
  final String status; // scheduled | in_progress | done | canceled
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<String> technicianIds;
  final List<OrderChecklistItem> checklist;
  final List<OrderMaterialItem> materials;
  final OrderBilling billing;
  final OrderTimesheet timesheet;
  final List<String> photoUrls;
  final String? customerSignatureUrl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final OrderAudit audit;

  /// Informações adicionais que o backend pode enviar em listagens
  final String? clientName;
  final String? locationLabel;
  final String? equipmentLabel;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.locationId,
    required this.status,
    this.equipmentId,
    this.scheduledAt,
    this.startedAt,
    this.finishedAt,
    this.technicianIds = const [],
    this.checklist = const [],
    this.materials = const [],
    OrderBilling? billing,
    OrderTimesheet? timesheet,
    this.photoUrls = const [],
    this.customerSignatureUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
    OrderAudit? audit,
    this.clientName,
    this.locationLabel,
    this.equipmentLabel,
  }) : billing = billing ?? OrderBilling.empty(),
       timesheet = timesheet ?? OrderTimesheet.empty(),
       audit = audit ?? OrderAudit.empty();

  bool get isScheduled => status == 'scheduled';
  bool get isInProgress => status == 'in_progress';
  bool get isDone => status == 'done';
  bool get isCanceled => status == 'canceled';

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final id = _string(map, ['id', '_id']);
    final clientId = _string(map, ['clientId']) ?? '';
    final locationId = _string(map, ['locationId']) ?? '';
    final equipmentId = _string(map, ['equipmentId']);
    final status = _string(map, ['status']) ?? 'scheduled';

    DateTime? _tryParseDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is DateTime) return value;
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final scheduledAt = _tryParseDate(map['scheduledAt'] ?? map['scheduled']);
    final startedAt = _tryParseDate(map['startedAt']);
    final finishedAt = _tryParseDate(map['finishedAt']);

    final techs =
        _list(
          map['technicianIds'],
        ).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    final checklist =
        _list(map['checklist'])
            .map(
              (e) => OrderChecklistItem.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

    final materials =
        _list(map['materials'])
            .map(
              (e) => OrderMaterialItem.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

    final billing =
        map['billing'] is Map<String, dynamic>
            ? OrderBilling.fromMap(map['billing'] as Map<String, dynamic>)
            : OrderBilling.empty();

    final timesheet =
        map['timesheet'] is Map<String, dynamic>
            ? OrderTimesheet.fromMap(map['timesheet'] as Map<String, dynamic>)
            : OrderTimesheet.empty();

    final photoUrls = _list(map['photoUrls']).map((e) => e.toString()).toList();
    final customerSignatureUrl = _string(map, [
      'customerSignatureUrl',
      'signatureUrl',
    ]);
    final notes = _string(map, ['notes']);

    final createdAt = _tryParseDate(map['createdAt']);
    final updatedAt = _tryParseDate(map['updatedAt']);

    final audit =
        map['audit'] is Map<String, dynamic>
            ? OrderAudit.fromMap(map['audit'] as Map<String, dynamic>)
            : OrderAudit.empty();

    // Campos auxiliares
    String? clientName;
    final client = map['client'];
    if (client is Map) {
      clientName = _string(client, ['name']);
    } else {
      clientName = _string(map, ['clientName']);
    }

    String? locationLabel;
    final location = map['location'];
    if (location is Map) {
      locationLabel =
          _string(location, ['label']) ?? _string(location, ['name']);
    } else {
      locationLabel = _string(map, ['locationLabel', 'locationName']);
    }

    String? equipmentLabel;
    final equipment = map['equipment'];
    if (equipment is Map) {
      equipmentLabel =
          _string(equipment, ['name']) ?? _string(equipment, ['label']);
    } else {
      equipmentLabel = _string(map, ['equipmentName', 'equipmentLabel']);
    }

    return OrderModel(
      id: id ?? '',
      clientId: clientId,
      locationId: locationId,
      equipmentId: equipmentId,
      status: status,
      scheduledAt: scheduledAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
      technicianIds: techs,
      checklist: checklist,
      materials: materials,
      billing: billing,
      timesheet: timesheet,
      photoUrls: photoUrls,
      customerSignatureUrl: customerSignatureUrl,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      audit: audit,
      clientName: clientName,
      locationLabel: locationLabel,
      equipmentLabel: equipmentLabel,
    );
  }

  OrderModel copyWith({
    String? status,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<String>? technicianIds,
    List<OrderChecklistItem>? checklist,
    List<OrderMaterialItem>? materials,
    OrderBilling? billing,
    OrderTimesheet? timesheet,
    List<String>? photoUrls,
    String? customerSignatureUrl,
    String? notes,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id,
      clientId: clientId,
      locationId: locationId,
      equipmentId: equipmentId,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      technicianIds: technicianIds ?? this.technicianIds,
      checklist: checklist ?? this.checklist,
      materials: materials ?? this.materials,
      billing: billing ?? this.billing,
      timesheet: timesheet ?? this.timesheet,
      photoUrls: photoUrls ?? this.photoUrls,
      customerSignatureUrl: customerSignatureUrl ?? this.customerSignatureUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      audit: audit,
      clientName: clientName,
      locationLabel: locationLabel,
      equipmentLabel: equipmentLabel,
    );
  }
}

class OrderChecklistItem {
  final String item;
  final bool done;
  final String? note;
  final List<String> photoUrls;

  OrderChecklistItem({
    required this.item,
    this.done = false,
    this.note,
    this.photoUrls = const [],
  });

  factory OrderChecklistItem.fromMap(Map<String, dynamic> map) {
    return OrderChecklistItem(
      item: _string(map, ['item', 'text']) ?? '',
      done:
          map['done'] == true ||
          map['checked'] == true ||
          map['status'] == 'done',
      note: _string(map, ['note', 'observation']),
      photoUrls: _list(map['photoUrls']).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'item': item,
    'done': done,
    if (note != null) 'note': note,
    if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
  };
}

class OrderMaterialItem {
  final String itemId;
  final num qty;
  final bool reserved;
  final DateTime? deductedAt;
  final String? itemName;

  OrderMaterialItem({
    required this.itemId,
    required this.qty,
    this.reserved = false,
    this.deductedAt,
    this.itemName,
  });

  factory OrderMaterialItem.fromMap(Map<String, dynamic> map) {
    DateTime? deducted;
    final rawDeducted = map['deductedAt'];
    if (rawDeducted != null) {
      try {
        deducted = DateTime.parse(rawDeducted.toString());
      } catch (_) {
        deducted = null;
      }
    }
    return OrderMaterialItem(
      itemId: _string(map, ['itemId']) ?? '',
      qty: (map['qty'] ?? map['quantity'] ?? 0) as num,
      reserved: map['reserved'] == true,
      deductedAt: deducted,
      itemName: _string(map, ['itemName', 'name']),
    );
  }

  Map<String, dynamic> toJson() => {'itemId': itemId, 'qty': qty};
}

class OrderBillingItem {
  final String type; // service | part
  final String name;
  final num qty;
  final num unitPrice;

  OrderBillingItem({
    required this.type,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  factory OrderBillingItem.fromMap(Map<String, dynamic> map) {
    return OrderBillingItem(
      type: _string(map, ['type']) ?? 'service',
      name: _string(map, ['name']) ?? '',
      qty: (map['qty'] ?? map['quantity'] ?? 0) as num,
      unitPrice: (map['unitPrice'] ?? map['price'] ?? 0) as num,
    );
  }

  num get lineTotal => qty * unitPrice;

  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'qty': qty,
    'unitPrice': unitPrice,
  };
}

class OrderBilling {
  final List<OrderBillingItem> items;
  final num subtotal;
  final num discount;
  final num total;
  final String status;

  OrderBilling({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
  });

  factory OrderBilling.fromMap(Map<String, dynamic> map) {
    final items =
        _list(map['items'])
            .map(
              (e) =>
                  OrderBillingItem.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
    num subtotal =
        map['subtotal'] is num
            ? map['subtotal'] as num
            : items.fold<num>(0, (sum, item) => sum + item.lineTotal);

    return OrderBilling(
      items: items,
      subtotal: subtotal,
      discount: (map['discount'] ?? 0) as num,
      total: (map['total'] ?? subtotal) as num,
      status: _string(map, ['status']) ?? 'pending',
    );
  }

  factory OrderBilling.empty() => OrderBilling(
    items: const [],
    subtotal: 0,
    discount: 0,
    total: 0,
    status: 'pending',
  );
}

class OrderTimesheet {
  final DateTime? start;
  final DateTime? end;
  final int? totalMinutes;

  OrderTimesheet({this.start, this.end, this.totalMinutes});

  factory OrderTimesheet.fromMap(Map<String, dynamic> map) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? totalMin;
    final total = map['totalMin'] ?? map['totalMinutes'];
    if (total is num) totalMin = total.toInt();

    return OrderTimesheet(
      start: parse(map['start']),
      end: parse(map['end']),
      totalMinutes: totalMin,
    );
  }

  factory OrderTimesheet.empty() => OrderTimesheet();
}

class OrderAudit {
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;

  const OrderAudit({this.createdBy, this.updatedBy, this.deletedAt});

  factory OrderAudit.fromMap(Map<String, dynamic> map) {
    DateTime? deletedAt;
    final raw = map['deletedAt'];
    if (raw != null) {
      try {
        deletedAt = DateTime.parse(raw.toString());
      } catch (_) {
        deletedAt = null;
      }
    }
    return OrderAudit(
      createdBy: _string(map, ['createdBy']),
      updatedBy: _string(map, ['updatedBy']),
      deletedAt: deletedAt,
    );
  }

  factory OrderAudit.empty() => const OrderAudit();
}

List<dynamic> _list(dynamic value) {
  if (value is List) return value;
  if (value == null) return const [];
  return const [];
}

String? _string(dynamic source, List<String> keys) {
  if (source is Map) {
    for (final key in keys) {
      if (source.containsKey(key) && source[key] != null) {
        final value = source[key];
        if (value == null) return null;
        return value.toString();
      }
    }
  } else if (source != null && keys.isEmpty) {
    return source.toString();
  }
  return null;
}

class OrderChecklistInput {
  final String item;
  final bool? done;
  final String? note;
  final List<String>? photoUrls;

  OrderChecklistInput({
    required this.item,
    this.done,
    this.note,
    this.photoUrls,
  });

  Map<String, dynamic> toJson() => {
    'item': item,
    if (done != null) 'done': done,
    if (note != null) 'note': note,
    if (photoUrls != null) 'photoUrls': photoUrls,
  };
}

class OrderMaterialInput {
  final String itemId;
  final num qty;

  OrderMaterialInput({required this.itemId, required this.qty});

  Map<String, dynamic> toJson() => {'itemId': itemId, 'qty': qty};
}

class OrderBillingItemInput {
  final String type; // service | part
  final String name;
  final num qty;
  final num unitPrice;

  OrderBillingItemInput({
    required this.type,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'qty': qty,
    'unitPrice': unitPrice,
  };
}

extension OrderChecklistInputX on Iterable<OrderChecklistInput> {
  List<Map<String, dynamic>> toJsonList() =>
      map((e) => e.toJson()).toList(growable: false);
}

extension OrderMaterialInputX on Iterable<OrderMaterialInput> {
  List<Map<String, dynamic>> toJsonList() =>
      map((e) => e.toJson()).toList(growable: false);
}

extension OrderBillingItemInputX on Iterable<OrderBillingItemInput> {
  List<Map<String, dynamic>> toJsonList() =>
      map((e) => e.toJson()).toList(growable: false);
}
