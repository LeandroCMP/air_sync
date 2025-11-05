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
    List<String> permissions = const [],
  }) : permissions =
           permissions.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

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

  bool hasPermission(String code) {
    final normalized = code.toLowerCase();
    for (final permission in permissions) {
      if (permission.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  bool hasAnyPermission(Iterable<String> codes) {
    for (final code in codes) {
      if (hasPermission(code)) {
        return true;
      }
    }
    return false;
  }

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
      dateBorn:
          map['dateBorn'] != null
              ? DateTime.tryParse(map['dateBorn'].toString())
              : null,
      userLevel: map['userLevel'] ?? 0,
      planExpiration:
          map['planExpiration'] != null
              ? DateTime.tryParse(map['planExpiration'].toString())
              : null,
      cpfOrCnpj: map['cpfOrCnpj'] ?? '',
      role: (map['role'] ?? '').toString(),
      permissions:
          ((map['permissions'] as List?) ?? const [])
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
