import 'air_conditioner_model.dart';

class ResidenceModel {
  final String id;
  final String name;
  final String number;
  final String complement;
  final String street;
  final String zipCode;
  final String city;
  final List<AirConditionerModel> airConditioners;

  ResidenceModel({
    required this.id,
    required this.name,
    required this.number,
    required this.complement,
    required this.street,
    required this.zipCode,
    required this.city,
    this.airConditioners = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'complement': complement,
      'street': street,
      'zipCode': zipCode,
      'city': city,
      'airConditioners': airConditioners.map((e) => e.toMap()).toList(),
    };
  }

  factory ResidenceModel.fromMap(Map<String, dynamic> map) {
    return ResidenceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      number: map['number'] ?? '',
      complement: map['complement'] ?? '',
      street: map['street'] ?? '',
      zipCode: map['zipCode'] ?? '',
      city: map['city'] ?? '',
      airConditioners: (map['airConditioners'] as List<dynamic>? ?? [])
          .map((e) => AirConditionerModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
