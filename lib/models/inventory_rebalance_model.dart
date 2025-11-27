class InventoryRebalanceSuggestion {
  final String itemId;
  final String name;
  final String? sku;
  final double available;
  final double dailyUsage;
  final double recommendedQty;
  final double? unitCost;
  final String? unit;
  final String? supplierId;

  const InventoryRebalanceSuggestion({
    required this.itemId,
    required this.name,
    required this.available,
    required this.dailyUsage,
    required this.recommendedQty,
    this.sku,
    this.unitCost,
    this.unit,
    this.supplierId,
  });

  factory InventoryRebalanceSuggestion.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return InventoryRebalanceSuggestion(
      itemId: (map['itemId'] ?? map['id'] ?? '').toString(),
      name: (map['name'] ?? map['itemName'] ?? 'Item').toString(),
      sku: (map['sku'] ?? map['code'])?.toString(),
      available: parseDouble(map['available'] ?? map['onHand']),
      dailyUsage: parseDouble(map['dailyUsage'] ?? map['consumptionRate']),
      recommendedQty: parseDouble(
        map['recommendedQty'] ?? map['suggestedQty'] ?? map['suggestion'],
      ),
      unitCost: map['unitCost'] != null
          ? parseDouble(map['unitCost'])
          : map['avgCost'] != null
              ? parseDouble(map['avgCost'])
              : null,
      unit: (map['unit'] ?? map['uom'])?.toString(),
      supplierId: (map['supplierId'] ?? map['preferredSupplierId'])?.toString(),
    );
  }
}

