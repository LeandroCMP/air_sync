class FleetVehicleModel {
  final String id;
  final String plate;
  final String? model;
  final int? year;
  final int odometer;
  FleetVehicleModel({required this.id, required this.plate, this.model, this.year, required this.odometer});
  factory FleetVehicleModel.fromMap(Map<String, dynamic> m) => FleetVehicleModel(
        id: (m['id'] ?? m['_id'] ?? '').toString(),
        plate: (m['plate'] ?? '').toString(),
        model: m['model']?.toString(),
        year: m['year'] is num ? (m['year'] as num).toInt() : null,
        odometer: m['odometer'] is num ? (m['odometer'] as num).toInt() : 0,
      );
}

