import 'package:air_sync/models/purchase_model.dart';

class CreateOrderPurchaseItemDto {
  const CreateOrderPurchaseItemDto({
    required this.itemId,
    required this.qty,
    this.unitCost,
    this.description,
    this.costCenterId,
  });

  final String itemId;
  final double qty;
  final double? unitCost;
  final String? description;
  final String? costCenterId;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'itemId': itemId,
        'qty': qty,
        if (unitCost != null) 'unitCost': unitCost,
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        if (costCenterId != null && costCenterId!.trim().isNotEmpty)
          'costCenterId': costCenterId!.trim(),
      };

  PurchaseItemModel toPurchaseItem({required String orderId}) {
    return PurchaseItemModel(
      itemId: itemId,
      qty: qty,
      unitCost: unitCost ?? 0,
      description: description,
      orderId: orderId,
      costCenterId: costCenterId,
    );
  }
}

class CreateOrderPurchaseDto {
  CreateOrderPurchaseDto({
    required this.supplierId,
    this.items,
    this.freight,
    this.paymentDueDate,
    this.notes,
  });

  final String supplierId;
  final List<CreateOrderPurchaseItemDto>? items;
  final double? freight;
  final DateTime? paymentDueDate;
  final String? notes;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'supplierId': supplierId,
      if (freight != null) 'freight': freight,
      if (paymentDueDate != null)
        'paymentDueDate': paymentDueDate!.toUtc().toIso8601String(),
      if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
    };
    if (items != null && items!.isNotEmpty) {
      map['items'] = items!.map((e) => e.toMap()).toList();
    }
    return map;
  }

  List<PurchaseItemModel> toPurchaseItems({required String orderId}) {
    if (items == null) return const <PurchaseItemModel>[];
    return items!.map((e) => e.toPurchaseItem(orderId: orderId)).toList();
  }
}
