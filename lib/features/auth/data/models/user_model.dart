import '../../domain/entities/user.dart';

class UserModel extends AuthUser {
  const UserModel({required super.id, required super.name, required super.email, required super.permissions});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        permissions: (json['permissions'] as List<dynamic>? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'permissions': permissions,
      };
}
