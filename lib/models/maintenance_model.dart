class MaintenanceModel {
  final String id;
  final DateTime date;
  final String description;

  MaintenanceModel({
    required this.id,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory MaintenanceModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        if (value > 1e12) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      if (value is num) {
        final millis =
            value.abs() > 1e12
                ? value.toInt()
                : (value.toDouble() * 1000).round();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final rawDate =
        map['date'] ??
        map['at'] ??
        map['createdAt'] ??
        map['performedAt'] ??
        map['updatedAt'];
    DateTime? parsedDate;
    parsedDate = parseDate(rawDate);
    parsedDate ??= DateTime.now();

    final idRaw =
        map['id'] ??
        map['_id'] ??
        map['eventId'] ??
        map['orderId'] ??
        map['reference'];
    final descriptionRaw =
        map['description'] ??
        map['notes'] ??
        map['summary'] ??
        map['type'] ??
        map['title'] ??
        '';
    return MaintenanceModel(
      id: idRaw?.toString() ?? parsedDate.millisecondsSinceEpoch.toString(),
      date: parsedDate,
      description: descriptionRaw?.toString() ?? '',
    );
  }
}
