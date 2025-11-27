import 'package:air_sync/models/inventory_entry_model.dart';

enum MovementType {
  receive,
  issue,
  adjustPos,
  adjustNeg,
  transferIn,
  transferOut,
  returnIn,
}

String? _normalizeString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().replaceAll(',', '.').trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

DateTime _parseMovementDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is num) {
    final ms = value.abs() > 1e12 ? value.toInt() : (value * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return DateTime.now();
  return DateTime.tryParse(text) ?? DateTime.now();
}

List<StockMovementModel> _convertLegacyEntries(
  List<dynamic> rawEntries,
  String itemId,
) {
  final result = <StockMovementModel>[];
  for (var i = 0; i < rawEntries.length; i++) {
    try {
      final entry = Map<String, dynamic>.from(rawEntries[i] as Map);
      final qtyRaw = entry['qty'] ?? entry['quantity'] ?? entry['amount'] ?? 0;
      final qty =
          qtyRaw is num
              ? qtyRaw.toDouble()
              : double.tryParse(qtyRaw.toString()) ?? 0;
      if (qty <= 0) continue;

      final typeRaw = (entry['type'] ?? '').toString().toLowerCase();
      MovementType type;
      switch (typeRaw) {
        case 'in':
          type = MovementType.receive;
          break;
        case 'out':
          type = MovementType.issue;
          break;
        case 'adjust_pos':
          type = MovementType.adjustPos;
          break;
        case 'adjust_neg':
          type = MovementType.adjustNeg;
          break;
        case 'transfer_in':
          type = MovementType.transferIn;
          break;
        case 'transfer_out':
          type = MovementType.transferOut;
          break;
        case 'return_in':
          type = MovementType.returnIn;
          break;
        case 'reserve':
          type = MovementType.adjustNeg;
          break;
        case 'release':
          type = MovementType.adjustPos;
          break;
        default:
          type = MovementType.receive;
      }

      final id = (entry['id'] ?? entry['_id'] ?? 'legacy-$i').toString();
      final createdAt = _parseMovementDate(entry['at'] ?? entry['date']);
      final reason = entry['ref']?.toString();
      final documentRef = entry['lot']?.toString();
      final performedBy = entry['by']?.toString();

      result.add(
        StockMovementModel(
          id: id,
          itemId: itemId,
          locationId: null,
          quantity: qty.abs(),
          type: type,
          reason: reason,
          documentRef: documentRef,
          idempotencyKey: null,
          performedBy: performedBy,
          createdAt: createdAt,
        ),
      );
    } catch (_) {
      // ignora entrada malformatada
    }
  }
  return result;
}

class StockMovementModel {
  final String id;
  final String itemId;
  final String? locationId;
  final double quantity; // sempre > 0
  final MovementType type;
  final String? reason;
  final String? documentRef;
  final String? idempotencyKey;
  final String? performedBy;
  final DateTime createdAt;

  StockMovementModel({
    required this.id,
    required this.itemId,
    this.locationId,
    required this.quantity,
    required this.type,
    this.reason,
    this.documentRef,
    this.idempotencyKey,
    this.performedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      if (locationId != null) 'locationId': locationId,
      'quantity': quantity,
      'type': type.name.toUpperCase(),
      if (reason != null) 'reason': reason,
      if (documentRef != null) 'documentRef': documentRef,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      if (performedBy != null) 'performedBy': performedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    final t = (map['type'] ?? '').toString().toUpperCase();
    MovementType mt;
    switch (t) {
      case 'RECEIVE':
        mt = MovementType.receive;
        break;
      case 'ISSUE':
        mt = MovementType.issue;
        break;
      case 'ADJUST_POS':
        mt = MovementType.adjustPos;
        break;
      case 'ADJUST_NEG':
        mt = MovementType.adjustNeg;
        break;
      case 'TRANSFER_IN':
        mt = MovementType.transferIn;
        break;
      case 'TRANSFER_OUT':
        mt = MovementType.transferOut;
        break;
      case 'RETURN_IN':
        mt = MovementType.returnIn;
        break;
      default:
        mt = MovementType.receive;
    }
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final qty = map['quantity'] ?? map['qty'] ?? 0;
    return StockMovementModel(
      id: id,
      itemId: (map['itemId'] ?? '').toString(),
      locationId: map['locationId']?.toString(),
      quantity:
          (qty is num) ? qty.toDouble() : double.tryParse(qty.toString()) ?? 0,
      type: mt,
      reason: map['reason']?.toString(),
      documentRef: map['documentRef']?.toString(),
      idempotencyKey: map['idempotencyKey']?.toString(),
      performedBy: map['performedBy']?.toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class StockLevelModel {
  final String itemId;
  final String? locationId;
  final double onHand;
  final DateTime? updatedAt;

  StockLevelModel({
    required this.itemId,
    this.locationId,
    required this.onHand,
    this.updatedAt,
  });

  factory StockLevelModel.fromMap(Map<String, dynamic> map) {
    final qty = map['onHand'] ?? map['quantity'] ?? map['qty'] ?? 0;
    return StockLevelModel(
      itemId: (map['itemId'] ?? '').toString(),
      locationId: map['locationId']?.toString(),
      onHand:
          (qty is num) ? qty.toDouble() : double.tryParse(qty.toString()) ?? 0,
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  if (value is Map) {
    final millisCandidate =
        value['milliseconds'] ?? value['_milliseconds'] ?? value['ms'];
    if (millisCandidate != null) {
      final ms =
          millisCandidate is num
              ? millisCandidate.toInt()
              : int.tryParse(millisCandidate.toString());
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final secondsCandidate =
        value['seconds'] ?? value['_seconds'] ?? value['epochSeconds'];
    if (secondsCandidate != null) {
      final sec =
          secondsCandidate is num
              ? secondsCandidate.toDouble()
              : double.tryParse(secondsCandidate.toString());
      if (sec != null) {
        final ms = (sec * 1000).round();
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    final isoCandidate =
        value['iso'] ?? value['iso8601'] ?? value['date'] ?? value['timestamp'];
    if (isoCandidate != null) {
      return DateTime.tryParse(isoCandidate.toString());
    }
  }

  if (value is num) {
    final ms = value.abs() > 1e12 ? value.toInt() : (value * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return DateTime.tryParse(text);
}

class InventoryCostHistoryEntry {
  final double cost;
  final DateTime at;
  final String? source;

  const InventoryCostHistoryEntry({
    required this.cost,
    required this.at,
    this.source,
  });

  factory InventoryCostHistoryEntry.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return InventoryCostHistoryEntry(
      cost: parseDouble(map['cost']),
      at: _parseMovementDate(map['at'] ?? map['date']),
      source: map['source']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'cost': cost,
        'at': at.toIso8601String(),
        if (source != null) 'source': source,
      };
}

class InventoryItemModel {
  final String id;
  final String userId;
  final String description; // nome
  final String sku;
  final String unit; // 'UN'|'KG'|'L'|...
  final double quantity; // saldo consolidado (onHand)
  final double minQuantity; // obrigatório >= 0
  final bool active;
  final String? barcode;
  final double? maxQuantity;
  final String? supplierId;
  final double? avgCost;
  final double? sellPrice;
  final String? categoryId;
  final double? markupPercent;
  final String pricingMode; // manual | category
  final double? suggestedSellPrice;
  final double? priceDeviationPercent;
  final double? priceDeviationValue;
  final double? lastPurchaseCost;
  final List<InventoryCostHistoryEntry> costHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<InventoryEntryModel> entries; // legado/compatibilidade local
  final List<StockMovementModel> movements;

  // Compatibilidade e conveniências
  String get name => description;
  double get onHand => quantity;
  bool get belowMinimum => onHand <= minQuantity;

  InventoryItemModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.minQuantity,
    required this.active,
    this.barcode,
    this.maxQuantity,
    this.supplierId,
    this.avgCost,
    this.sellPrice,
    this.categoryId,
    this.markupPercent,
    this.pricingMode = 'manual',
    this.suggestedSellPrice,
    this.priceDeviationPercent,
    this.priceDeviationValue,
    this.lastPurchaseCost,
    this.costHistory = const [],
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.entries = const [],
    this.movements = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'userId': userId,
      'name': description,
      'sku': sku,
      'unit': unit.toUpperCase(),
      'onHand': quantity,
      'minQuantity': minQuantity,
      'active': active,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (maxQuantity != null) 'maxQty': maxQuantity,
      if (supplierId != null && supplierId!.isNotEmpty)
        'supplierId': supplierId,
      if (avgCost != null) 'avgCost': avgCost,
      if (sellPrice != null) 'sellPrice': sellPrice,
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      if (markupPercent != null) 'markupPercent': markupPercent,
      'pricingMode': pricingMode,
      if (suggestedSellPrice != null)
        'suggestedSellPrice': suggestedSellPrice,
      if (priceDeviationPercent != null)
        'priceDeviationPercent': priceDeviationPercent,
      if (priceDeviationValue != null)
        'priceDeviationValue': priceDeviationValue,
      if (lastPurchaseCost != null) 'lastPurchaseCost': lastPurchaseCost,
      if (costHistory.isNotEmpty)
        'costHistory': costHistory.map((e) => e.toMap()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
      'entries': entries.map((e) => e.toMap()).toList(),
      'movements': movements.map((e) => e.toMap()).toList(),
    };
  }

  factory InventoryItemModel.fromMap(String id, Map<String, dynamic> map) {
    final qty =
        map['onHand'] ?? map['quantity'] ?? map['qty'] ?? map['stock'] ?? 0;
    final minQ = map['minQuantity'] ?? map['minQty'] ?? 0;
    final unitRaw = (map['unit'] ?? map['uom'] ?? '').toString();
    final barcodeRaw = map['barcode'] ?? map['barCode'];
    final supplierIdRaw = map['supplierId'];
    final maxQtyRaw = map['maxQty'] ?? map['maxQuantity'];
    final avgCostRaw = map['avgCost'] ?? map['averageCost'];
    final sellPriceRaw = map['sellPrice'] ?? map['price'];
    final categoryIdRaw = map['categoryId'];
    final markupRaw = map['markupPercent'] ?? map['markup'];
    final pricingModeRaw = (map['pricingMode'] ?? 'manual').toString();
    final suggestedSellPriceRaw = map['suggestedSellPrice'];
    final priceDeviationPercentRaw =
        map['priceDeviationPercent'] ?? map['priceDeviationPct'];
    final priceDeviationValueRaw = map['priceDeviationValue'];
    final lastPurchaseCostRaw =
        map['lastPurchaseCost'] ?? map['lastCost'] ?? map['recentCost'];
    List<StockMovementModel> parseMovements(dynamic source) {
      if (source == null) return const [];
      final list = <StockMovementModel>[];
      if (source is List) {
        for (final entry in source) {
          try {
            list.add(
              StockMovementModel.fromMap(
                Map<String, dynamic>.from(entry as Map),
              ),
            );
          } catch (_) {}
        }
      } else if (source is Map) {
        final nested =
            source['items'] ??
            source['data'] ??
            source['results'] ??
            source['movements'];
        list.addAll(parseMovements(nested));
      }
      return list;
    }

    final movementsRaw =
        map['movements'] ??
        map['movementHistory'] ??
        map['history'] ??
        map['stockMovements'];
    final costHistoryRaw =
        map['costHistory'] ??
        map['cost_history'] ??
        map['costHistoryEntries'] ??
        map['costHistoryList'];
    final parsedCostHistory = <InventoryCostHistoryEntry>[];
    if (costHistoryRaw is List) {
      for (final entry in costHistoryRaw) {
        if (entry is Map) {
          try {
            parsedCostHistory.add(
              InventoryCostHistoryEntry.fromMap(
                Map<String, dynamic>.from(entry),
              ),
            );
          } catch (_) {}
        }
      }
    }
    final rawEntries = (map['entries'] as List<dynamic>? ?? []);
    final parsedEntries =
        rawEntries
            .map(
              (e) => InventoryEntryModel.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList();
    final apiMovements = parseMovements(movementsRaw);
    final fallbackMovements =
        apiMovements.isNotEmpty
            ? apiMovements
            : _convertLegacyEntries(rawEntries, id);
    return InventoryItemModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      description: (map['name'] ?? map['description'] ?? '').toString(),
      sku: (map['sku'] ?? '').toString(),
      unit: unitRaw.isEmpty ? 'UN' : unitRaw.toUpperCase(),
      quantity:
          (qty is num) ? qty.toDouble() : double.tryParse(qty.toString()) ?? 0,
      minQuantity:
          (minQ is num)
              ? minQ.toDouble()
              : double.tryParse(minQ.toString()) ?? 0,
      active:
          (map['active'] is bool)
              ? (map['active'] as bool)
              : (((map['active'] ?? 'true').toString().toLowerCase()) !=
                  'false'),
      barcode: _normalizeString(barcodeRaw),
      maxQuantity: _parseNullableDouble(maxQtyRaw),
      supplierId: _normalizeString(supplierIdRaw),
      avgCost: _parseNullableDouble(avgCostRaw),
      sellPrice: _parseNullableDouble(sellPriceRaw),
      categoryId: _normalizeString(categoryIdRaw),
      markupPercent: _parseNullableDouble(markupRaw),
      pricingMode: pricingModeRaw.isEmpty
          ? 'manual'
          : pricingModeRaw.toLowerCase(),
      suggestedSellPrice: _parseNullableDouble(suggestedSellPriceRaw),
      priceDeviationPercent:
          _parseNullableDouble(priceDeviationPercentRaw),
      priceDeviationValue: _parseNullableDouble(priceDeviationValueRaw),
      lastPurchaseCost: _parseNullableDouble(lastPurchaseCostRaw),
      costHistory: parsedCostHistory,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      deletedAt: _parseDate(map['deletedAt']),
      entries: parsedEntries,
      movements: fallbackMovements,
    );
  }

  InventoryItemModel copyWith({
    String? id,
    String? userId,
    String? description,
    String? sku,
    String? unit,
    double? quantity,
    double? minQuantity,
    bool? active,
    String? barcode,
    double? maxQuantity,
    String? supplierId,
    double? avgCost,
    double? sellPrice,
    String? categoryId,
    double? markupPercent,
    String? pricingMode,
    double? suggestedSellPrice,
    double? priceDeviationPercent,
    double? priceDeviationValue,
    double? lastPurchaseCost,
    List<InventoryCostHistoryEntry>? costHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<InventoryEntryModel>? entries,
    List<StockMovementModel>? movements,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      active: active ?? this.active,
      barcode: barcode ?? this.barcode,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      supplierId: supplierId ?? this.supplierId,
      avgCost: avgCost ?? this.avgCost,
      sellPrice: sellPrice ?? this.sellPrice,
      categoryId: categoryId ?? this.categoryId,
      markupPercent: markupPercent ?? this.markupPercent,
      pricingMode: pricingMode ?? this.pricingMode,
      suggestedSellPrice: suggestedSellPrice ?? this.suggestedSellPrice,
      priceDeviationPercent:
          priceDeviationPercent ?? this.priceDeviationPercent,
      priceDeviationValue: priceDeviationValue ?? this.priceDeviationValue,
      lastPurchaseCost: lastPurchaseCost ?? this.lastPurchaseCost,
      costHistory: costHistory ?? this.costHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      entries: entries ?? this.entries,
      movements: movements ?? this.movements,
    );
  }
}
