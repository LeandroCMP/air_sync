class ClientModel {
  final String id;
  final String name;
  final List<String> phones;
  final List<String> emails;
  final String? docNumber;
  final List<String> tags;
  final String? notes;

  ClientModel({
    required this.id,
    required this.name,
    this.phones = const [],
    this.emails = const [],
    this.docNumber,
    this.tags = const [],
    this.notes,
  });

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';

  Map<String, dynamic> toCreatePayload() {
    return {
      'name': name,
      if (phones.isNotEmpty) 'phones': phones,
      if (emails.isNotEmpty) 'emails': emails,
      if (docNumber != null && docNumber!.isNotEmpty) 'docNumber': docNumber,
      if (tags.isNotEmpty) 'tags': tags,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'name': name,
      'phones': phones,
      'emails': emails,
      'docNumber': docNumber,
      'tags': tags,
      'notes': notes,
    };
  }

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
    return ClientModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      phones: (map['phones'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      emails: (map['emails'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      docNumber: map['docNumber']?.toString() ?? map['document']?.toString(),
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      notes: map['notes']?.toString(),
    );
  }

  ClientModel copyWith({
    String? id,
    String? name,
    List<String>? phones,
    List<String>? emails,
    String? docNumber,
    List<String>? tags,
    String? notes,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      docNumber: docNumber ?? this.docNumber,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }
}
