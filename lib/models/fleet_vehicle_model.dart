class FleetVehicleModel {
  final String id;
  final String plate;
  final String? model;
  final int? year;
  final int odometer;
  FleetVehicleModel({
    required this.id,
    required this.plate,
    this.model,
    this.year,
    required this.odometer,
  });
  factory FleetVehicleModel.fromMap(Map<String, dynamic> m) {
    final plateRaw = (m['plate'] ?? '').toString().trim();
    final modelRaw = (m['model']?.toString() ?? '').trim();
    return FleetVehicleModel(
      id: (m['id'] ?? m['_id'] ?? '').toString(),
      plate: plateRaw.toUpperCase(),
      model: modelRaw.isEmpty ? null : modelRaw.toUpperCase(),
      year: m['year'] is num ? (m['year'] as num).toInt() : null,
      odometer: m['odometer'] is num ? (m['odometer'] as num).toInt() : 0,
    );
  }
}

class FleetInsightRecommendation {
  const FleetInsightRecommendation({
    required this.title,
    required this.description,
    this.priority,
  });

  final String title;
  final String description;
  final String? priority;

  factory FleetInsightRecommendation.fromMap(Map<String, dynamic> map) {
    return FleetInsightRecommendation(
      title: (map['title'] ?? map['headline'] ?? 'Recomendação').toString(),
      description: (map['description'] ?? map['details'] ?? '').toString(),
      priority: map['priority']?.toString(),
    );
  }
}

class FleetInsightChatResponse {
  const FleetInsightChatResponse({
    required this.answer,
    this.metadata,
  });

  final String answer;
  final Map<String, dynamic>? metadata;

  factory FleetInsightChatResponse.fromMap(Map<String, dynamic> map) {
    return FleetInsightChatResponse(
      answer: (map['answer'] ?? map['message'] ?? map['response'] ?? '').toString(),
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }
}
