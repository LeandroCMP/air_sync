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
    this.mustChangePassword = false,
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
  final bool mustChangePassword;

  bool get isOwner => role.toLowerCase() == 'owner';

  bool hasPermission(String code) {
    if (isOwner) return true;
    final normalized = code.toLowerCase();
    for (final permission in permissions) {
      if (permission.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  bool hasAnyPermission(Iterable<String> codes) {
    if (isOwner) return true;
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
      'mustChangePassword': mustChangePassword,
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
      permissions: ((map['permissions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      mustChangePassword:
          map['mustChangePassword'] == true || map['must_change_password'] == true,
    );
  }

  String toJson() => json.encode({...toMap(), 'id': id});

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    DateTime? dateBorn,
    int? userLevel,
    DateTime? planExpiration,
    String? cpfOrCnpj,
    String? role,
    List<String>? permissions,
    bool? mustChangePassword,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateBorn: dateBorn ?? this.dateBorn,
      userLevel: userLevel ?? this.userLevel,
      planExpiration: planExpiration ?? this.planExpiration,
      cpfOrCnpj: cpfOrCnpj ?? this.cpfOrCnpj,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, dateBorn: $dateBorn, phone: $phone, userLevel: $userLevel, planExpiration: $planExpiration, cpfOrCnpj: $cpfOrCnpj, role: $role, permissions: $permissions, mustChangePassword: $mustChangePassword)';
  }
}
