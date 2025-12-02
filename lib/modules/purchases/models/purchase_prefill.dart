class PurchasePrefillItem {
  final String itemId;
  final String? itemName;
  final double quantity;
  final double unitCost;
  final String? orderId;

  const PurchasePrefillItem({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    this.itemName,
    this.orderId,
  });
}

class PurchasePrefillData {
  final String? supplierId;
  final List<PurchasePrefillItem> items;

  const PurchasePrefillData({
    this.supplierId,
    required this.items,
  });

  bool get hasItems => items.isNotEmpty;
}
