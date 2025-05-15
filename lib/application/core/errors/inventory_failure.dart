class InventoryFailure implements Exception {
  final String message;

  InventoryFailure._(this.message);

  factory InventoryFailure.firebase(String message) =>
      InventoryFailure._('[FIREBASE] $message');

  factory InventoryFailure.validation(String message) =>
      InventoryFailure._('[VALIDATION] $message');

  factory InventoryFailure.unknown(String message) =>
      InventoryFailure._('[UNKNOWN] $message');

  @override
  String toString() => message;
}
