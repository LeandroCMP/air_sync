DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed.toUtc();
    }
    return null;
  }
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((element) => element.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }
  return const [];
}

class ClientModel {
  final String id;
  final String name;
  final String? docNumber;
  final List<String> phones;
  final List<String> emails;
  final String? notes;
  final String? tenantId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ClientModel({
    required this.id,
    required this.name,
    this.docNumber,
    this.phones = const [],
    this.emails = const [],
    this.notes,
    this.tenantId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';

  String get primaryEmail => emails.isNotEmpty ? emails.first : '';

  Map<String, dynamic> toCreatePayload() {
    return {
      'name': name.trim(),
      if (docNumber != null && docNumber!.trim().isNotEmpty)
        'docNumber': docNumber!.trim(),
      if (phones.isNotEmpty) 'phones': phones,
      if (emails.isNotEmpty) 'emails': emails,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }

  Map<String, dynamic> toUpdatePayload({ClientModel? original}) {
    final payload = <String, dynamic>{};

    void setField(String key, dynamic value, dynamic previous) {
      if (value == null) return;
      if (value is String) {
        final trimmed = value.trim();
        if (original == null || trimmed != (previous ?? '').toString()) {
          payload[key] = trimmed;
        }
      } else if (value is List<String>) {
        if (original == null ||
            previous is! List ||
            !_listEquals(previous, value)) {
          payload[key] = value;
        }
      } else if (original == null || value != previous) {
        payload[key] = value;
      }
    }

    setField('name', name, original?.name);
    setField('docNumber', docNumber, original?.docNumber);
    setField('phones', phones, original?.phones);
    setField('emails', emails, original?.emails);
    setField('notes', notes, original?.notes);

    return payload;
  }

  static bool _listEquals(List<dynamic>? a, List<dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? docNumber,
    List<String>? phones,
    List<String>? emails,
    String? notes,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      docNumber: docNumber ?? this.docNumber,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      notes: notes ?? this.notes,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
    final meta =
        map['_audit'] is Map ? Map<String, dynamic>.from(map['_audit']) : null;
    final data = Map<String, dynamic>.from(map);
    data.remove('_audit');

    return ClientModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      docNumber: data['docNumber']?.toString() ?? data['document']?.toString(),
      phones: _asStringList(data['phones']),
      emails: _asStringList(data['emails']),
      notes: data['notes']?.toString(),
      tenantId: data['tenantId']?.toString(),
      createdAt: _parseDate(data['createdAt'] ?? meta?['createdAt']),
      updatedAt: _parseDate(data['updatedAt'] ?? meta?['updatedAt']),
      deletedAt: _parseDate(data['deletedAt']),
    );
  }

  factory ClientModel.fromResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final id = (data['id'] ?? data['_id'] ?? '').toString();
        final combined = Map<String, dynamic>.from(data);
        if (response['_audit'] is Map) {
          combined['_audit'] = response['_audit'];
        }
        return ClientModel.fromMap(id, combined);
      }
      final id = (response['id'] ?? response['_id'] ?? '').toString();
      return ClientModel.fromMap(id, response);
    }
    throw ArgumentError('Resposta de cliente inválida');
  }
}
