class PurchaseItemModel {
  final String itemId;
  final double qty;
  final double unitCost;
  PurchaseItemModel({required this.itemId, required this.qty, required this.unitCost});
  factory PurchaseItemModel.fromMap(Map<String, dynamic> m) => PurchaseItemModel(
        itemId: (m['itemId'] ?? '').toString(),
        qty: (m['qty'] as num).toDouble(),
        unitCost: (m['unitCost'] as num).toDouble(),
      );
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
  final String? notes;
  PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.status,
    required this.items,
    required this.total,
    this.subtotal,
    this.freight,
    this.createdAt,
    this.receivedAt,
    this.notes,
  });

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final totals = (map['totals'] as Map?) ?? {};
    return PurchaseModel(
      id: id,
      supplierId: (map['supplierId'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      items: ((map['items'] as List?) ?? [])
          .map((e) => PurchaseItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      total: (totals['total'] ?? 0) is num ? (totals['total'] as num).toDouble() : 0,
      subtotal: (totals['subtotal'] ?? 0) is num ? (totals['subtotal'] as num).toDouble() : null,
      freight: (totals['freight'] ?? totals['frete'] ?? 0) is num ? ((totals['freight'] ?? totals['frete']) as num).toDouble() : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      receivedAt: map['receivedAt'] != null ? DateTime.tryParse(map['receivedAt'].toString()) : null,
      notes: map['notes']?.toString(),
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
    String? notes,
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
      notes: notes ?? this.notes,
    );
  }
}

