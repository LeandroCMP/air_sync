class SupplierModel {
  final String id;
  final String name;
  final String? docNumber;
  final String? phone;
  final String? email;
  final String? notes;

  SupplierModel({
    required this.id,
    required this.name,
    this.docNumber,
    this.phone,
    this.email,
    this.notes,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] ?? map['_id'] ?? '').toString();
    return SupplierModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      docNumber: map['docNumber']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}

