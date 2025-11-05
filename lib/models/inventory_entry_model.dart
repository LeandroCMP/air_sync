DateTime _parseEntryDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;

  if (value is Map) {
    final millis = value['milliseconds'] ?? value['ms'];
    if (millis != null) {
      final parsed =
          millis is num ? millis.toInt() : int.tryParse(millis.toString());
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsed);
      }
    }
    final seconds = value['seconds'] ?? value['epochSeconds'];
    if (seconds != null) {
      final parsed =
          seconds is num
              ? seconds.toDouble()
              : double.tryParse(seconds.toString());
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch((parsed * 1000).round());
      }
    }
    final iso =
        value['iso'] ?? value['iso8601'] ?? value['date'] ?? value['timestamp'];
    if (iso != null) {
      final dt = DateTime.tryParse(iso.toString());
      if (dt != null) return dt;
    }
  }

  if (value is num) {
    final ms = value.abs() > 1e12 ? value.toInt() : (value * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  final text = value.toString().trim();
  final parsed = DateTime.tryParse(text);
  return parsed ?? DateTime.now();
}

class InventoryEntryModel {
  final DateTime date;
  final double quantity;

  InventoryEntryModel({required this.date, required this.quantity});

  Map<String, dynamic> toMap() {
    return {'date': date.toIso8601String(), 'quantity': quantity};
  }

  factory InventoryEntryModel.fromMap(Map<String, dynamic> map) {
    return InventoryEntryModel(
      date: _parseEntryDate(map['date']),
      quantity:
          (map['quantity'] is num)
              ? (map['quantity'] as num).toDouble()
              : double.tryParse(map['quantity']?.toString() ?? '') ?? 0,
    );
  }
}
