import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateBorn,
    required this.userLevel,
    required this.planExpiration,
    required this.cpfOrCnpj,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? dateBorn;
  final int userLevel;
  final DateTime? planExpiration;
  final String cpfOrCnpj;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name.toUpperCase(),
      'email': email.toUpperCase(),
      'phone': phone,
      'dateBorn': dateBorn != null ? Timestamp.fromDate(dateBorn!) : null,
      'userLevel': userLevel,
      'planExpiration':
          planExpiration != null ? Timestamp.fromDate(planExpiration!) : null,
      'cpfOrCnpj': cpfOrCnpj,
    };
  }

  factory UserModel.fromMap(
    Map<String, dynamic> map,
    String uid,
    String? email,
  ) {
    return UserModel(
      id: uid,
      name: map['name'] ?? '',
      email: email ?? '',
      phone: map['phone'] ?? '',
      dateBorn:
          map['dateBorn'] is Timestamp
              ? (map['dateBorn'] as Timestamp).toDate()
              : null,
      userLevel: map['userLevel'] ?? 0,
      planExpiration:
          map['planExpiration'] is Timestamp
              ? (map['planExpiration'] as Timestamp).toDate()
              : null,
      cpfOrCnpj: map['cpfOrCnpj'] ?? '',
    );
  }

  String toJson() => json.encode({...toMap(), 'id': id});

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, dateBorn: $dateBorn, phone: $phone, userLevel: $userLevel, planExpiration: $planExpiration, cpfOrCnpj: $cpfOrCnpj)';
  }
}
