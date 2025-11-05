import 'package:air_sync/models/fleet_vehicle_model.dart';
import 'package:air_sync/repositories/fleet/fleet_repository.dart';
import 'package:air_sync/services/fleet/fleet_service.dart';

class FleetServiceImpl implements FleetService {
  final FleetRepository _repo;
  FleetServiceImpl({required FleetRepository repo}) : _repo = repo;

  @override
  Future<void> check({required String id, int? odometer, int? fuelLevel, String? notes}) =>
      _repo.check(id: id, odometer: odometer, fuelLevel: fuelLevel, notes: notes);

  @override
  Future<void> fuel({required String id, required double liters, required double price, required String fuelType, int? odometer}) =>
      _repo.fuel(id: id, liters: liters, price: price, fuelType: fuelType, odometer: odometer);

  @override
  Future<List<FleetVehicleModel>> list({String? text, String? sort, String? order}) =>
      _repo.list(text: text, sort: sort, order: order);

  @override
  Future<void> maintenance({required String id, required String description, double? cost, int? odometer}) =>
      _repo.maintenance(id: id, description: description, cost: cost, odometer: odometer);

  @override
  Future<FleetVehicleModel> create({required String plate, String? model, int? year, required int odometer}) =>
      _repo.create(plate: plate, model: model, year: year, odometer: odometer);

  @override
  Future<FleetVehicleModel> update(String id, {String? plate, String? model, int? year, int? odometer}) =>
      _repo.update(id, plate: plate, model: model, year: year, odometer: odometer);

  @override
  Future<void> delete(String id) => _repo.delete(id);

  @override
  Future<List<Map<String, dynamic>>> listEvents(
    String id, {
    int page = 1,
    int limit = 50,
    List<String>? types,
    DateTime? from,
    DateTime? to,
    String? sort,
    String? order,
  }) =>
      _repo.listEvents(
        id,
        page: page,
        limit: limit,
        types: types,
        from: from,
        to: to,
        sort: sort,
        order: order,
      );
}
