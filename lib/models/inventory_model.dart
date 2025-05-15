import 'package:air_sync/models/inventory_entry_model.dart';

class InventoryItemModel {
  final String id;
  final String userId;
  final String description;
  final String unit;
  final double quantity;
  final List<InventoryEntryModel> entries;

  InventoryItemModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.unit,
    required this.quantity,
    this.entries = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'userId': userId,
      'description': description.toUpperCase(),
      'unit': unit.toUpperCase(),
      'quantity': quantity,
      'entries': entries.map((e) => e.toMap()).toList(),
    };
  }

  factory InventoryItemModel.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItemModel(
      id: id,
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      entries: (map['entries'] as List<dynamic>? ?? [])
          .map((e) => InventoryEntryModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  InventoryItemModel copyWith({
    String? id,
    String? userId,
    String? description,
    String? unit,
    double? quantity,
    List<InventoryEntryModel>? entries,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      entries: entries ?? this.entries,
    );
  }
}
