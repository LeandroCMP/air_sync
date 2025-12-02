class PurchaseItemModel {
  final String itemId;
  final double qty;
  final double unitCost;
  final String? description;
  final String? orderId;

  const PurchaseItemModel({
    required this.itemId,
    required this.qty,
    required this.unitCost,
    this.description,
    this.orderId,
  });

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PurchaseItemModel(
      itemId: (map['itemId'] ?? '').toString(),
      qty: asDouble(map['qty']),
      unitCost: asDouble(map['unitCost']),
      description:
          (map['description'] ?? map['name'] ?? map['itemName'])?.toString(),
      orderId: (map['orderId'] ?? map['osId'] ?? map['order_id'])?.toString(),
    );
  }

  PurchaseItemModel copyWith({
    String? itemId,
    double? qty,
    double? unitCost,
    String? description,
    String? orderId,
  }) {
    return PurchaseItemModel(
      itemId: itemId ?? this.itemId,
      qty: qty ?? this.qty,
      unitCost: unitCost ?? this.unitCost,
      description: description ?? this.description,
      orderId: orderId ?? this.orderId,
    );
  }
}

class PurchaseAlertModel {
  final String type;
  final String? itemId;
  final double? deltaPercent;
  final String message;

  PurchaseAlertModel({
    required this.type,
    this.itemId,
    this.deltaPercent,
    required this.message,
  });

  factory PurchaseAlertModel.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return PurchaseAlertModel(
      type: (map['type'] ?? map['code'] ?? '').toString(),
      itemId: map['itemId']?.toString(),
      deltaPercent: parseDouble(map['deltaPercent'] ?? map['deltaPct']),
      message: (map['message'] ?? '').toString(),
    );
  }
}

class PurchaseClassificationModel {
  final String categoryId;
  final String categoryName;
  final double total;

  const PurchaseClassificationModel({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });

  factory PurchaseClassificationModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PurchaseClassificationModel(
        categoryId: '',
        categoryName: 'Sem categoria',
        total: 0,
      );
    }
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return PurchaseClassificationModel(
      categoryId: (map['categoryId'] ?? map['id'] ?? '').toString(),
      categoryName: (map['categoryName'] ?? map['name'] ?? 'Sem categoria')
          .toString(),
      total: parseDouble(map['total'] ?? map['value']),
    );
  }
}

class PurchaseModel {
  final String id;
  final String supplierId;
  final String status;
  final List<PurchaseItemModel> items;
  final double total;
  final double? subtotal;
  final double? freight;
  final DateTime? createdAt;
  final DateTime? receivedAt;
  final DateTime? paymentDueDate;
  final String? notes;
  final List<PurchaseAlertModel> alerts;
  final List<PurchaseClassificationModel> classifications;
  final List<PurchaseHistoryEntry> history;
  final String? lastNotification;

  const PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.status,
    required this.items,
    required this.total,
    this.subtotal,
    this.freight,
    this.createdAt,
    this.receivedAt,
    this.paymentDueDate,
    this.notes,
    this.alerts = const [],
    this.classifications = const [],
    this.history = const [],
    this.lastNotification,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    double parseNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final text = value.toString();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final totals = (map['totals'] as Map?) ?? {};
    final historyRaw =
        ((map['history'] ?? map['timeline'] ?? map['events']) as List?) ?? [];

    return PurchaseModel(
      id: id,
      supplierId: (map['supplierId'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      items: ((map['items'] as List?) ?? [])
          .whereType<Map>()
          .map(
            (e) => PurchaseItemModel.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      total: parseNum(totals['total'] ?? map['total']),
      subtotal: totals['subtotal'] is num
          ? (totals['subtotal'] as num).toDouble()
          : null,
      freight: (totals['freight'] ?? totals['frete']) is num
          ? ((totals['freight'] ?? totals['frete']) as num).toDouble()
          : null,
      createdAt: parseDate(map['createdAt']),
      receivedAt: parseDate(map['receivedAt']),
      paymentDueDate: parseDate(map['paymentDueDate']),
      notes: map['notes']?.toString(),
      alerts: ((map['alerts'] as List?) ?? [])
          .whereType<Map>()
          .map(
            (e) => PurchaseAlertModel.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      classifications: ((map['classifications'] ??
                  map['categories'] ??
                  map['categoryTotals']) as List? ??
              [])
          .whereType<Map>()
          .map(
            (e) => PurchaseClassificationModel.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      history: historyRaw
          .whereType<Map>()
          .map(
            (entry) => PurchaseHistoryEntry.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(),
      lastNotification:
          (map['notification'] ?? map['message'] ?? map['lastNotification'])
              ?.toString(),
    );
  }

  PurchaseModel copyWith({
    String? id,
    String? supplierId,
    String? status,
    List<PurchaseItemModel>? items,
    double? total,
    double? subtotal,
    double? freight,
    DateTime? createdAt,
    DateTime? receivedAt,
    DateTime? paymentDueDate,
    String? notes,
    List<PurchaseAlertModel>? alerts,
    List<PurchaseClassificationModel>? classifications,
    List<PurchaseHistoryEntry>? history,
    String? lastNotification,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      items: items ?? this.items,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      freight: freight ?? this.freight,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      notes: notes ?? this.notes,
      alerts: alerts ?? this.alerts,
      classifications: classifications ?? this.classifications,
      history: history ?? this.history,
      lastNotification: lastNotification ?? this.lastNotification,
    );
  }
}

class PurchaseHistoryEntry {
  final String status;
  final String? userId;
  final String? userName;
  final DateTime? createdAt;
  final String? notes;

  const PurchaseHistoryEntry({
    required this.status,
    this.userId,
    this.userName,
    this.createdAt,
    this.notes,
  });

  factory PurchaseHistoryEntry.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is num) {
        final millis =
            value.abs() > 1e12 ? value.toInt() : (value.toDouble() * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return PurchaseHistoryEntry(
      status: (map['status'] ?? map['state'] ?? '').toString(),
      userId: (map['userId'] ?? map['updatedBy'] ?? map['actorId'])?.toString(),
      userName: (map['userName'] ??
              map['user'] ??
              map['updatedByName'] ??
              map['actorName'])
          ?.toString(),
      createdAt: parseDate(
        map['createdAt'] ?? map['timestamp'] ?? map['date'] ?? map['updatedAt'],
      ),
      notes: (map['notes'] ?? map['comment'])?.toString(),
    );
  }
}
