import 'dart:convert';

import '../../domain/entities/order.dart';

class OrderModel extends ServiceOrder {
  OrderModel({
    required super.id,
    required super.status,
    required super.clientName,
    required super.location,
    required super.equipment,
    required super.scheduledAt,
    required super.updatedAt,
    super.totalMinutes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        status: json['status'] as String? ?? 'scheduled',
        clientName: json['client']?['name'] as String? ?? json['clientName'] as String? ?? '',
        location: json['location']?['name'] as String? ?? json['locationName'] as String?,
        equipment: json['equipment']?['name'] as String? ?? json['equipmentName'] as String?,
        scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt'] as String) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
        totalMinutes: json['totalMinutes'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'clientName': clientName,
        'locationName': location,
        'equipmentName': equipment,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'totalMinutes': totalMinutes,
      };

  String toDatabase() => jsonEncode(toJson());

  factory OrderModel.fromDatabase(Map<String, Object?> row) {
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return OrderModel.fromJson(payload);
  }
}
