enum ClientFailureType {
  validationError,
  firebaseError,
  unknown,
}

class ClientFailure implements Exception {
  final ClientFailureType type;
  final String message;

  const ClientFailure(this.type, this.message);

  factory ClientFailure.validation(String message) {
    return ClientFailure(ClientFailureType.validationError, message);
  }

  factory ClientFailure.firebase(String message) {
    return ClientFailure(ClientFailureType.firebaseError, message);
  }

  factory ClientFailure.unknown([String message = 'Erro desconhecido']) {
    return ClientFailure(ClientFailureType.unknown, message);
  }

  @override
  String toString() => 'ClientFailure(type: $type, message: $message)';
}
