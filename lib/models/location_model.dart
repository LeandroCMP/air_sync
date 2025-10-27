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

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    final address = (map['address'] as Map?) ?? {};
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
}

