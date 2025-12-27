class MaintenanceReminderModel {
  MaintenanceReminderModel({
    required this.serviceName,
    required this.serviceTypeCode,
    required this.nextDueAt,
    required this.status,
    this.equipmentId,
    this.orderId,
  });

  final String serviceName;
  final String serviceTypeCode;
  final DateTime? nextDueAt;
  final String status;
  final String? equipmentId;
  final String? orderId;

  factory MaintenanceReminderModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is num) {
        final millis =
            value > 1e12 ? value.toInt() : (value.toDouble() * 1000).round();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return MaintenanceReminderModel(
      serviceName: (map['serviceName'] ?? map['name'] ?? '').toString(),
      serviceTypeCode: (map['serviceTypeCode'] ?? map['code'] ?? '').toString(),
      nextDueAt: parseDate(map['nextDueAt'] ?? map['dueAt'] ?? map['dueDate']),
      status: (map['status'] ?? '').toString(),
      equipmentId: map['equipmentId']?.toString(),
      orderId: map['orderId']?.toString(),
    );
  }
}
