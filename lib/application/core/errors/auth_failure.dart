import 'dart:async';
import 'dart:io';

enum AuthFailureType {
  wrongPassword,
  userNotFound,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  networkError,
  timeout,
  unknown,
}

class AuthFailure implements Exception {
  final AuthFailureType type;
  final String message;

  const AuthFailure(this.type, this.message);

  /// Mensagem padrão para cada tipo (usada se não houver mensagem específica).
  static String messageForType(AuthFailureType type) {
    switch (type) {
      case AuthFailureType.wrongPassword:
        return 'Senha inválida.';
      case AuthFailureType.userNotFound:
        return 'Usuário não encontrado.';
      case AuthFailureType.invalidEmail:
        return 'E-mail inválido.';
      case AuthFailureType.userDisabled:
        return 'Usuário desativado.';
      case AuthFailureType.tooManyRequests:
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case AuthFailureType.networkError:
        return 'Falha de conexão. Verifique sua internet.';
      case AuthFailureType.timeout:
        return 'Tempo de resposta excedido. Tente novamente.';
      case AuthFailureType.unknown:
        return 'Erro desconhecido.';
    }
  }

  /// Constrói um [AuthFailure] a partir de qualquer [Exception] comum no login.
  factory AuthFailure.fromException(Exception e) {
    if (e is TimeoutException) {
      return AuthFailure(
        AuthFailureType.timeout,
        messageForType(AuthFailureType.timeout),
      );
    }

    if (e is SocketException || e is HandshakeException) {
      return AuthFailure(
        AuthFailureType.networkError,
        messageForType(AuthFailureType.networkError),
      );
    }

    if (e is FormatException) {
      return const AuthFailure(
        AuthFailureType.unknown,
        'Resposta inválida do servidor.',
      );
    }

    final runtime = e.runtimeType.toString();
    if (runtime == 'FirebaseAuthException') {
      try {
        final code = (e as dynamic).code as String?;
        final msg = (e as dynamic).message as String?;
        switch (code) {
          case 'wrong-password':
          case 'invalid-credential':
            return AuthFailure(
              AuthFailureType.wrongPassword,
              msg ?? messageForType(AuthFailureType.wrongPassword),
            );
          case 'user-not-found':
            return AuthFailure(
              AuthFailureType.userNotFound,
              msg ?? messageForType(AuthFailureType.userNotFound),
            );
          case 'invalid-email':
            return AuthFailure(
              AuthFailureType.invalidEmail,
              msg ?? messageForType(AuthFailureType.invalidEmail),
            );
          case 'user-disabled':
            return AuthFailure(
              AuthFailureType.userDisabled,
              msg ?? messageForType(AuthFailureType.userDisabled),
            );
          case 'too-many-requests':
            return AuthFailure(
              AuthFailureType.tooManyRequests,
              msg ?? messageForType(AuthFailureType.tooManyRequests),
            );
          case 'network-request-failed':
            return AuthFailure(
              AuthFailureType.networkError,
              msg ?? messageForType(AuthFailureType.networkError),
            );
          default:
            return AuthFailure(
              AuthFailureType.unknown,
              msg ?? messageForType(AuthFailureType.unknown),
            );
        }
      } catch (_) {
        return AuthFailure(
          AuthFailureType.unknown,
          messageForType(AuthFailureType.unknown),
        );
      }
    }

    return AuthFailure(
      AuthFailureType.unknown,
      messageForType(AuthFailureType.unknown),
    );
  }
}

