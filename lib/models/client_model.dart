import 'package:cloud_firestore/cloud_firestore.dart';
import 'residence_model.dart';

class ClientModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? cpfOrCnpj;
  final DateTime? birthDate;
  final List<ResidenceModel> residences;

  ClientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.cpfOrCnpj,
    this.birthDate,
    this.residences = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'userId': userId,
      'name': name.toUpperCase(),
      'phone': phone,
      'cpfOrCnpj': cpfOrCnpj,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'residences': residences.map((e) => e.toMap()).toList(),
    };
  }

  factory ClientModel.fromMap(String id, Map<String, dynamic> map) {
  return ClientModel(
    id: map['_id'],
    userId: map['userId'],
    name: map['name'],
    phone: map['phone'],
    cpfOrCnpj: map['cpfOrCnpj'],
    birthDate: map['birthDate'] != null && map['birthDate'] is Timestamp
        ? (map['birthDate'] as Timestamp).toDate()
        : null,
    residences: (map['residences'] as List<dynamic>? ?? [])
        .map((e) => ResidenceModel.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

  ClientModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? cpfOrCnpj,
    DateTime? birthDate,
    List<ResidenceModel>? residences,
  }) {
    return ClientModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cpfOrCnpj: cpfOrCnpj ?? this.cpfOrCnpj,
      birthDate: birthDate ?? this.birthDate,
      residences: residences ?? this.residences,
    );
  }
}
