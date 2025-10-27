class TimelineEntryModel {
  final String id;
  final String clientId;
  final String type; // call|whatsapp|email|note|nps
  final DateTime at;
  final String text;
  final String? by;
  TimelineEntryModel({
    required this.id,
    required this.clientId,
    required this.type,
    required this.at,
    required this.text,
    this.by,
  });
  factory TimelineEntryModel.fromMap(Map<String, dynamic> m) => TimelineEntryModel(
        id: (m['id'] ?? m['_id'] ?? '').toString(),
        clientId: (m['clientId'] ?? '').toString(),
        type: (m['type'] ?? '').toString(),
        at: DateTime.tryParse(m['at']?.toString() ?? '') ?? DateTime.now(),
        text: (m['text'] ?? '').toString(),
        by: m['by']?.toString(),
      );
}

