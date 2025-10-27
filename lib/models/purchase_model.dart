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
  final String? notes;
  PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.status,
    required this.items,
    required this.total,
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
      notes: map['notes']?.toString(),
    );
  }
}

