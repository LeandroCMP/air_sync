class MaintenanceModel {
  final String id;
  final DateTime date;
  final String description;

  MaintenanceModel({
    required this.id,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory MaintenanceModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}
