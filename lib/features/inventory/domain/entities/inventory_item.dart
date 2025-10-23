import 'package:equatable/equatable.dart';

class InventoryItem extends Equatable {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.onHand,
    required this.reserved,
    required this.minQty,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String sku;
  final int onHand;
  final int reserved;
  final int minQty;
  final DateTime? updatedAt;

  bool get isLowStock => onHand <= minQty;

  @override
  List<Object?> get props => [id, name, sku, onHand, reserved, minQty, updatedAt];
}
