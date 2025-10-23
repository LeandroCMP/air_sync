import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.name, required this.email, required this.permissions});

  final String id;
  final String name;
  final String email;
  final List<String> permissions;

  @override
  List<Object?> get props => [id, name, email, permissions];
}
