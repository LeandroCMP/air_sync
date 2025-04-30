import 'maintenance_model.dart';

class AirConditionerModel {
  final String id;
  final String room;
  final String model;
  final int btus;
  final List<MaintenanceModel> maintenances;

  AirConditionerModel({
    required this.id,
    required this.room,
    required this.model,
    required this.btus,
    this.maintenances = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room': room,
      'model': model,
      'btus': btus,
      'maintenances': maintenances.map((e) => e.toMap()).toList(),
    };
  }

  factory AirConditionerModel.fromMap(Map<String, dynamic> map) {
    return AirConditionerModel(
      id: map['id'],
      room: map['room'],
      model: map['model'],
      btus: map['btus'],
      maintenances: (map['maintenances'] as List<dynamic>? ?? [])
          .map((e) => MaintenanceModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
