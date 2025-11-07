import 'package:intl/intl.dart';

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
  final List<OrderPaymentEntry> payments;
  final double paymentGrossTotal;
  final double paymentFeeTotal;
  final double paymentNetTotal;
  final String? financeTransactionId;

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
    this.payments = const [],
    this.paymentGrossTotal = 0,
    this.paymentFeeTotal = 0,
    this.paymentNetTotal = 0,
    this.financeTransactionId,
  }) : billing = billing ?? OrderBilling.empty(),
       timesheet = timesheet ?? OrderTimesheet.empty(),
       audit = audit ?? OrderAudit.empty();

  bool get isScheduled => status == 'scheduled';
  bool get isInProgress => status == 'in_progress';
  bool get isDone => status == 'done';
  bool get isCanceled => status == 'canceled';
  bool get isDraft {
    if (status == 'draft') return true;
    final note = (notes ?? '').toLowerCase().trim();
    return note.startsWith('[rascunho');
  }

  static String _normalizeTimezone(String input) {
    final tzMatch = RegExp(r'([+-]\d{2})(\d{2})$').firstMatch(input);
    if (tzMatch != null && !input.contains(':', tzMatch.start + 1)) {
      return '${input.substring(0, tzMatch.start)}${tzMatch.group(1)}:${tzMatch.group(2)}';
    }
    return input;
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final id = _string(map, ['id', '_id']);
    final clientId = _string(map, ['clientId']) ?? '';
    final locationId = _string(map, ['locationId']) ?? '';
    final equipmentId = _string(map, ['equipmentId']);
    final status = _string(map, ['status']) ?? 'scheduled';

    DateTime? tryParseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Map) {
        final millis = value['milliseconds'] ?? value['ms'];
        if (millis != null) {
          final parsed =
              millis is num ? millis.toDouble() : double.tryParse('$millis');
          if (parsed != null) {
            return DateTime.fromMillisecondsSinceEpoch(parsed.round());
          }
        }
        final seconds = value['seconds'] ?? value['epochSeconds'];
        if (seconds != null) {
          final parsed =
              seconds is num ? seconds.toDouble() : double.tryParse('$seconds');
          if (parsed != null) {
            return DateTime.fromMillisecondsSinceEpoch((parsed * 1000).round());
          }
        }
        final micro = value['microseconds'];
        if (micro != null) {
          final parsed =
              micro is num ? micro.toDouble() : double.tryParse('$micro');
          if (parsed != null) {
            return DateTime.fromMicrosecondsSinceEpoch(parsed.round());
          }
        }
        final iso =
            value['iso'] ??
            value['iso8601'] ??
            value['date'] ??
            value['timestamp'];
        if (iso != null) {
          final normalizedIso = iso.toString().trim();
          if (normalizedIso.isNotEmpty) {
            final candidateIso = _normalizeTimezone(normalizedIso);
            final parsedIso = DateTime.tryParse(candidateIso);
            if (parsedIso != null) return parsedIso;
          }
        }
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is num) {
        final millis =
            value.abs() > 1e12
                ? value.toInt()
                : (value.toDouble() * 1000).round();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }

      final normalized = value.toString().trim();
      if (normalized.isEmpty) return null;

      final candidate = _normalizeTimezone(normalized);

      final numeric = int.tryParse(candidate);
      if (numeric != null) {
        final millis = candidate.length >= 13 ? numeric : (numeric * 1000);
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }

      final parsed = DateTime.tryParse(candidate);
      if (parsed != null) return parsed;

      const fallbackPatterns = [
        'yyyy-MM-dd HH:mm:ss',
        'yyyy/MM/dd HH:mm:ss',
        'yyyy-MM-dd HH:mm',
        'yyyy/MM/dd HH:mm',
        'dd/MM/yyyy HH:mm:ss',
        'dd/MM/yyyy HH:mm',
        'dd/MM/yyyy',
        'MM/dd/yyyy HH:mm:ss',
        'MM/dd/yyyy HH:mm',
        'MM/dd/yyyy',
      ];
      for (final pattern in fallbackPatterns) {
        try {
          final formatter = DateFormat(pattern);
          final parsedFallback = formatter.parseLoose(candidate);
          return parsedFallback;
        } catch (_) {
          // continue
        }
      }

      return null;
    }

    final scheduledAt = tryParseDate(map['scheduledAt'] ?? map['scheduled']);
    final startedAt = tryParseDate(map['startedAt']);
    final finishedAt = tryParseDate(map['finishedAt']);
    final createdAt = tryParseDate(map['createdAt']);
    final updatedAt = tryParseDate(map['updatedAt']);

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

    final payments =
        _list(map['payments'])
            .whereType<Map>()
            .map((e) => OrderPaymentEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
    final paymentGrossTotal =
        _parseNullableDouble(map['paymentGrossTotal']) ?? 0;
    final paymentFeeTotal = _parseNullableDouble(map['paymentFeeTotal']) ?? 0;
    final paymentNetTotal = _parseNullableDouble(map['paymentNetTotal']) ?? 0;
    final financeTransactionId = _string(map, [
      'financeTransactionId',
      'financeId',
    ]);

    final photoUrls = _list(map['photoUrls']).map((e) => e.toString()).toList();
    final customerSignatureUrl = _string(map, [
      'customerSignatureUrl',
      'signatureUrl',
    ]);
    final notes = _string(map, ['notes']);

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
      payments: payments,
      paymentGrossTotal: paymentGrossTotal,
      paymentFeeTotal: paymentFeeTotal,
      paymentNetTotal: paymentNetTotal,
      financeTransactionId: financeTransactionId,
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
    String? clientName,
    String? locationLabel,
    String? equipmentLabel,
    List<OrderPaymentEntry>? payments,
    double? paymentGrossTotal,
    double? paymentFeeTotal,
    double? paymentNetTotal,
    String? financeTransactionId,
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
      clientName: clientName ?? this.clientName,
      locationLabel: locationLabel ?? this.locationLabel,
      equipmentLabel: equipmentLabel ?? this.equipmentLabel,
      payments: payments ?? this.payments,
      paymentGrossTotal: paymentGrossTotal ?? this.paymentGrossTotal,
      paymentFeeTotal: paymentFeeTotal ?? this.paymentFeeTotal,
      paymentNetTotal: paymentNetTotal ?? this.paymentNetTotal,
      financeTransactionId: financeTransactionId ?? this.financeTransactionId,
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
  final String? description;
  final double? unitPrice;

  OrderMaterialItem({
    required this.itemId,
    required this.qty,
    this.reserved = false,
    this.deductedAt,
    this.itemName,
    this.description,
    this.unitPrice,
  });

  factory OrderMaterialItem.fromMap(Map<String, dynamic> map) {
    DateTime? deducted;
    final rawDeducted = map['deductedAt'];
    if (rawDeducted != null) {
      deducted = DateTime.tryParse(rawDeducted.toString());
    }
    return OrderMaterialItem(
      itemId: _string(map, ['itemId']) ?? '',
      qty: (map['qty'] ?? map['quantity'] ?? 0) as num,
      reserved: map['reserved'] == true,
      deductedAt: deducted,
      itemName: _string(map, [
        'itemName',
        'name',
        'description',
        'itemDescription',
      ]),
      description: _string(map, ['description', 'itemDescription']) ??
          _string(map, ['itemName', 'name']),
      unitPrice: _parseNullableDouble(map['unitPrice'] ?? map['price']),
    );
  }

  Map<String, dynamic> toJson() => {'itemId': itemId, 'qty': qty};

  OrderMaterialItem copyWith({
    String? itemId,
    num? qty,
    bool? reserved,
    DateTime? deductedAt,
    String? itemName,
    String? description,
    double? unitPrice,
  }) {
    return OrderMaterialItem(
      itemId: itemId ?? this.itemId,
      qty: qty ?? this.qty,
      reserved: reserved ?? this.reserved,
      deductedAt: deductedAt ?? this.deductedAt,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
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
      return DateTime.tryParse(v.toString());
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
      deletedAt = DateTime.tryParse(raw.toString());
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

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final normalized = text
      .replaceAll(RegExp(r'[^0-9,.\-]'), '')
      .replaceAll(',', '.');
  if (normalized.isEmpty || normalized == '-' || normalized == '.') return null;
  return double.tryParse(normalized);
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
  final String? itemName;
  final String? description;

  OrderMaterialInput({
    required this.itemId,
    required this.qty,
    this.itemName,
    this.description,
  });

  Map<String, dynamic> toJson({bool includeMetadata = true}) {
    final map = <String, dynamic>{
      'itemId': itemId,
      'qty': qty,
    };
    if (includeMetadata) {
      if (itemName != null && itemName!.trim().isNotEmpty) {
        map['itemName'] = itemName!.trim();
      }
      if (description != null && description!.trim().isNotEmpty) {
        map['description'] = description!.trim();
      }
    }
    return map;
  }
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
  List<Map<String, dynamic>> toJsonList({bool includeMetadata = true}) =>
      map((e) => e.toJson(includeMetadata: includeMetadata))
          .toList(growable: false);
}

extension OrderBillingItemInputX on Iterable<OrderBillingItemInput> {
  List<Map<String, dynamic>> toJsonList() =>
      map((e) => e.toJson()).toList(growable: false);
}

class OrderPaymentInput {
  OrderPaymentInput({
    required this.method,
    required this.amount,
    this.installments,
  });

  final String method;
  final double amount;
  final int? installments;

  Map<String, dynamic> toJson() => {
    'method': method,
    'amount': amount,
    if (installments != null) 'installments': installments,
  };
}

extension OrderPaymentInputX on Iterable<OrderPaymentInput> {
  List<Map<String, dynamic>> toJsonList() =>
      map((e) => e.toJson()).toList(growable: false);
}

class OrderPaymentEntry {
  OrderPaymentEntry({
    required this.method,
    required this.amount,
    this.installments,
    required this.feePercent,
    required this.feeValue,
    required this.netAmount,
  });

  final String method;
  final double amount;
  final int? installments;
  final double feePercent;
  final double feeValue;
  final double netAmount;

  factory OrderPaymentEntry.fromMap(Map<String, dynamic> map) {
    return OrderPaymentEntry(
      method: map['method']?.toString() ?? 'PIX',
      amount: _parseNullableDouble(map['amount']) ?? 0,
      installments:
          map['installments'] is num
              ? (map['installments'] as num).toInt()
              : null,
      feePercent: _parseNullableDouble(map['feePercent']) ?? 0,
      feeValue: _parseNullableDouble(map['feeValue']) ?? 0,
      netAmount: _parseNullableDouble(map['netAmount']) ?? 0,
    );
  }
}
