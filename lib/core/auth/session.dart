import 'package:equatable/equatable.dart';

class Session extends Equatable {
  const Session({
    required this.userId,
    required this.email,
    required this.name,
    required this.permissions,
    required this.tenantId,
    required this.accessToken,
    required this.refreshToken,
    required this.jti,
  });

  final String userId;
  final String email;
  final String name;
  final List<String> permissions;
  final String tenantId;
  final String accessToken;
  final String refreshToken;
  final String jti;

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    String? jti,
    List<String>? permissions,
  }) {
    return Session(
      userId: userId,
      email: email,
      name: name,
      permissions: permissions ?? this.permissions,
      tenantId: tenantId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      jti: jti ?? this.jti,
    );
  }

  @override
  List<Object?> get props => [userId, email, name, permissions, tenantId, accessToken, refreshToken, jti];
}
