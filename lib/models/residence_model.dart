import 'air_conditioner_model.dart';

class ResidenceModel {
  final String id;
  final String name;
  final List<AirConditionerModel> airConditioners;

  ResidenceModel({
    required this.id,
    required this.name,
    this.airConditioners = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'airConditioners': airConditioners.map((e) => e.toMap()).toList(),
    };
  }

  factory ResidenceModel.fromMap(Map<String, dynamic> map) {
    return ResidenceModel(
      id: map['id'],
      name: map['name'],
      airConditioners: (map['airConditioners'] as List<dynamic>? ?? [])
          .map((e) => AirConditionerModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
