class CostCenterModel {
  const CostCenterModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? code;
  final String? description;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CostCenterModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is num) {
        final millis =
            value.abs() > 1e12 ? value.toInt() : (value.toDouble() * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' ||
            normalized == '1' ||
            normalized == 'active';
      }
      return true;
    }

    return CostCenterModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      code: (map['code'] ?? map['shortCode'])?.toString(),
      description: (map['description'] ?? map['details'])?.toString(),
      active: parseBool(map['active'] ?? true),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  CostCenterModel copyWith({
    String? name,
    String? code,
    String? description,
    bool? active,
  }) {
    return CostCenterModel(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
