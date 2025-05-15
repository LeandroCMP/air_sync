class InventoryEntryModel {
  final DateTime date;
  final double quantity;

  InventoryEntryModel({
    required this.date,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'quantity': quantity,
    };
  }

  factory InventoryEntryModel.fromMap(Map<String, dynamic> map) {
    return InventoryEntryModel(
      date: DateTime.parse(map['date']),
      quantity: (map['quantity'] ?? 0).toDouble(),
    );
  }
}
