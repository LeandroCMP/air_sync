class PurchasePrefillItem {
  final String itemId;
  final String? itemName;
  final double quantity;
  final double unitCost;
  final String? orderId;
  final String? costCenterId;

  const PurchasePrefillItem({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    this.itemName,
    this.orderId,
    this.costCenterId,
  });
}

class PurchasePrefillData {
  final String? supplierId;
  final List<PurchasePrefillItem> items;
  final String? costCenterId;

  const PurchasePrefillData({
    this.supplierId,
    required this.items,
    this.costCenterId,
  });

  bool get hasItems => items.isNotEmpty;
}
