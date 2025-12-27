class WhatsAppStatus {
  WhatsAppStatus({
    required this.status,
    this.phoneId,
    this.message,
  });

  final String status;
  final String? phoneId;
  final String? message;

  factory WhatsAppStatus.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['status'] ?? map['state'] ?? '').toString();
    return WhatsAppStatus(
      status: rawStatus,
      phoneId: map['phoneId']?.toString(),
      message: map['message']?.toString(),
    );
  }

  bool get isConnected => status.toLowerCase() == 'connected';
  bool get isExpired => status.toLowerCase() == 'expired';

  String get label {
    final normalized = status.toLowerCase();
    if (normalized == 'connected') return 'Conectado';
    if (normalized == 'expired') return 'Expirado';
    return 'Nao conectado';
  }
}
