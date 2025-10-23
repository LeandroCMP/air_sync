import 'dart:convert';

import '../../domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel({
    required super.id,
    required super.name,
    required super.document,
    required super.phones,
    required super.emails,
    required super.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        document: json['document'] as String?,
        phones: (json['phones'] as List<dynamic>? ?? []).cast<String>(),
        emails: (json['emails'] as List<dynamic>? ?? []).cast<String>(),
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'document': document,
        'phones': phones,
        'emails': emails,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String toDatabase() => jsonEncode(toJson());

  factory ClientModel.fromDatabase(Map<String, Object?> row) {
    final payload = row['payload'] as String;
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return ClientModel.fromJson(json);
  }
}
