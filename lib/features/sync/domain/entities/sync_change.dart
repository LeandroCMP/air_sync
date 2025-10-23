class SyncChange {
  SyncChange({required this.entity, required this.operation, required this.payload});

  final String entity;
  final String operation;
  final Map<String, dynamic> payload;
}
