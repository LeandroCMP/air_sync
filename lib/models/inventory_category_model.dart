class InventoryCategoryModel {
  final String id;
  final String name;
  final double markupPercent;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryCategoryModel({
    required this.id,
    required this.name,
    required this.markupPercent,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryCategoryModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          value.abs() > 1e12 ? value.toInt() : (value * 1000).round(),
        );
      }
      final text = value.toString();
      if (text.isEmpty || text == 'null') return null;
      return DateTime.tryParse(text);
    }

    return InventoryCategoryModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      name: (map['name'] ?? map['title'] ?? '').toString(),
      markupPercent: parseDouble(map['markupPercent'] ?? map['markup']),
      description: map['description']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  InventoryCategoryModel copyWith({
    String? id,
    String? name,
    double? markupPercent,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      markupPercent: markupPercent ?? this.markupPercent,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
