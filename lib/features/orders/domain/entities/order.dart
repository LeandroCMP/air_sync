import 'package:equatable/equatable.dart';

class ServiceOrder extends Equatable {
  const ServiceOrder({
    required this.id,
    required this.status,
    required this.clientName,
    required this.location,
    required this.equipment,
    required this.scheduledAt,
    required this.updatedAt,
    this.totalMinutes,
  });

  final String id;
  final String status;
  final String clientName;
  final String? location;
  final String? equipment;
  final DateTime? scheduledAt;
  final DateTime? updatedAt;
  final int? totalMinutes;

  @override
  List<Object?> get props => [id, status, clientName, location, equipment, scheduledAt, updatedAt, totalMinutes];
}
