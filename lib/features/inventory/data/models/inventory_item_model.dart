import 'dart:convert';

import '../../domain/entities/inventory_item.dart';

class InventoryItemModel extends InventoryItem {
  InventoryItemModel({
    required super.id,
    required super.name,
    required super.sku,
    required super.onHand,
    required super.reserved,
    required super.minQty,
    required super.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) => InventoryItemModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        onHand: json['onHand'] as int? ?? 0,
        reserved: json['reserved'] as int? ?? 0,
        minQty: json['minQty'] as int? ?? 0,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'onHand': onHand,
        'reserved': reserved,
        'minQty': minQty,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String toDatabase() => jsonEncode(toJson());

  factory InventoryItemModel.fromDatabase(Map<String, Object?> row) {
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return InventoryItemModel.fromJson(payload);
  }
}
