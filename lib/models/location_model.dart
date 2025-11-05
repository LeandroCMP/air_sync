class LocationModel {
  final String id;
  final String clientId;
  final String label;
  final String? street;
  final String? number;
  final String? city;
  final String? state;
  final String? zip;
  final String? notes;

  LocationModel({
    required this.id,
    required this.clientId,
    required this.label,
    this.street,
    this.number,
    this.city,
    this.state,
    this.zip,
    this.notes,
  });

  String get addressLine {
    final parts = <String>[];
    if ((street ?? '').isNotEmpty) {
      parts.add(street!);
    }
    if ((number ?? '').isNotEmpty) {
      parts.add(number!);
    }
    return parts.join(', ');
  }

  String get cityState {
    final c = (city ?? '').trim();
    final s = (state ?? '').trim().toUpperCase();
    if (c.isEmpty && s.isEmpty) return '';
    if (c.isEmpty) return s;
    if (s.isEmpty) return c;
    return '$c - $s';
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final address = (map['address'] as Map?) ?? const {};
    return LocationModel(
      id: id,
      clientId: (map['clientId'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      street: address['street']?.toString(),
      number: address['number']?.toString(),
      city: address['city']?.toString(),
      state: address['state']?.toString(),
      zip: address['zip']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  LocationModel copyWith({
    String? id,
    String? clientId,
    String? label,
    String? street,
    String? number,
    String? city,
    String? state,
    String? zip,
    String? notes,
  }) {
    return LocationModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      label: label ?? this.label,
      street: street ?? this.street,
      number: number ?? this.number,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      notes: notes ?? this.notes,
    );
  }
}
