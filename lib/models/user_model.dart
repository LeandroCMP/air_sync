import 'dart:convert';

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
    this.role = '',
    this.permissions = const [],
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? dateBorn;
  final int userLevel;
  final DateTime? planExpiration;
  final String cpfOrCnpj;
  final String role;
  final List<String> permissions;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name.toUpperCase(),
      'email': email.toUpperCase(),
      'phone': phone,
      'dateBorn': dateBorn?.toIso8601String(),
      'userLevel': userLevel,
      'planExpiration': planExpiration?.toIso8601String(),
      'cpfOrCnpj': cpfOrCnpj,
      'role': role,
      'permissions': permissions,
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
      dateBorn: map['dateBorn'] != null
          ? DateTime.tryParse(map['dateBorn'].toString())
          : null,
      userLevel: map['userLevel'] ?? 0,
      planExpiration: map['planExpiration'] != null
          ? DateTime.tryParse(map['planExpiration'].toString())
          : null,
      cpfOrCnpj: map['cpfOrCnpj'] ?? '',
      role: (map['role'] ?? '').toString(),
      permissions: ((map['permissions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  String toJson() => json.encode({...toMap(), 'id': id});

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, dateBorn: $dateBorn, phone: $phone, userLevel: $userLevel, planExpiration: $planExpiration, cpfOrCnpj: $cpfOrCnpj, role: $role, permissions: $permissions)';
  }
}
