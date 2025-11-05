import 'package:air_sync/models/fleet_vehicle_model.dart';

abstract class FleetService {
  Future<List<FleetVehicleModel>> list({String? text, String? sort, String? order});
  Future<void> check({required String id, int? odometer, int? fuelLevel, String? notes});
  Future<void> fuel({required String id, required double liters, required double price, required String fuelType, int? odometer});
  Future<void> maintenance({required String id, required String description, double? cost, int? odometer});
  Future<FleetVehicleModel> create({required String plate, String? model, int? year, required int odometer});
  Future<FleetVehicleModel> update(String id, {String? plate, String? model, int? year, int? odometer});
  Future<void> delete(String id);
  Future<List<Map<String, dynamic>>> listEvents(
    String id, {
    int page = 1,
    int limit = 50,
    List<String>? types,
    DateTime? from,
    DateTime? to,
    String? sort,
    String? order,
  });
}
