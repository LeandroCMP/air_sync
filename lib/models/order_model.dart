class OrderModel {
  final String id;
  final String status; // scheduled | in_progress | finished | canceled
  final DateTime? scheduledAt;
  final String clientName;
  final String? location;
  final String? equipment;

  OrderModel({
    required this.id,
    required this.status,
    required this.scheduledAt,
    required this.clientName,
    this.location,
    this.equipment,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final status = (map['status'] ?? '').toString();
    final when = map['scheduledAt'] ?? map['date'] ?? map['scheduled'] ?? null;
    DateTime? scheduledAt;
    if (when != null) {
      try { scheduledAt = DateTime.parse(when.toString()); } catch (_) {}
    }
    // client may be nested or flat
    String clientName = '';
    final client = map['client'] as Map<String, dynamic>?;
    if (client != null) {
      clientName = (client['name'] ?? '').toString();
    } else {
      clientName = (map['clientName'] ?? '').toString();
    }
    final location = (map['location'] ?? map['address'] ?? map['place'])?.toString();
    final equipment = (map['equipment'] ?? map['device'] ?? map['machine'])?.toString();

    return OrderModel(
      id: id,
      status: status,
      scheduledAt: scheduledAt,
      clientName: clientName,
      location: location,
      equipment: equipment,
    );
  }
}

