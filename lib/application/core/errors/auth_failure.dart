// lib/repositories/auth/auth_failure.dart

import 'package:firebase_auth/firebase_auth.dart';

enum AuthFailureType {
  wrongPassword,
  userNotFound,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  unknown,
}

class AuthFailure implements Exception {
  final AuthFailureType type;
  final String message;

  const AuthFailure(this.type, this.message);

  // Método para mapear o erro a partir da exceção
  factory AuthFailure.fromException(Exception e) {
    if (e is FirebaseAuthException) {
      return _fromFirebaseAuthException(e);
    }
    return const AuthFailure(AuthFailureType.unknown, 'Erro desconhecido.');
  }

  // Método para mapear os códigos de erro do Firebase Auth
  static AuthFailure _fromFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return const AuthFailure(
          AuthFailureType.wrongPassword,
          'Usuário ou senha incorreta. Verifique e tente novamente.',
        );
      case 'user-not-found':
        return const AuthFailure(
          AuthFailureType.userNotFound,
          'Usuário não encontrado com esse e-mail.',
        );
      case 'invalid-email':
        return const AuthFailure(
          AuthFailureType.invalidEmail,
          'O e-mail informado é inválido.',
        );
      case 'user-disabled':
        return const AuthFailure(
          AuthFailureType.userDisabled,
          'Essa conta está desativada.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          AuthFailureType.tooManyRequests,
          'Muitas tentativas. Tente novamente mais tarde.',
        );
      default:
        return AuthFailure(
          AuthFailureType.unknown,
          'Erro de autenticação desconhecido: ${e.code}',
        );
    }
  }
}
