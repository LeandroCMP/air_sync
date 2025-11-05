import 'package:air_sync/models/equipment_model.dart';
import 'package:air_sync/models/maintenance_model.dart';
import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/services/equipments/equipments_service.dart';

class EquipmentsServiceImpl implements EquipmentsService {
  final EquipmentsRepository _repo;
  EquipmentsServiceImpl({required EquipmentsRepository repo}) : _repo = repo;

  @override
  Future<EquipmentModel> create({
    required String clientId,
    required String locationId,
    required String room,
    String? brand,
    String? model,
    String? type,
    int? btus,
    DateTime? installDate,
    String? serial,
    String? notes,
  }) => _repo.create(
    clientId: clientId,
    locationId: locationId,
    room: room,
    brand: brand,
    model: model,
    type: type,
    btus: btus,
    installDate: installDate,
    serial: serial,
    notes: notes,
  );

  @override
  Future<List<EquipmentModel>> listByClient(String clientId) =>
      _repo.listByClient(clientId);

  @override
  Future<List<EquipmentModel>> listBy(String clientId, {String? locationId}) =>
      _repo.listBy(clientId, locationId: locationId);

  @override
  Future<EquipmentModel> update({
    required String id,
    String? locationId,
    String? brand,
    String? model,
    String? type,
    int? btus,
    String? room,
    DateTime? installDate,
    String? serial,
    String? notes,
    bool includeNotes = false,
  }) => _repo.update(
    id: id,
    locationId: locationId,
    brand: brand,
    model: model,
    type: type,
    btus: btus,
    room: room,
    installDate: installDate,
    serial: serial,
    notes: notes,
    includeNotes: includeNotes,
  );

  @override
  Future<void> delete(String id) => _repo.delete(id);

  @override
  Future<List<Map<String, dynamic>>> listHistory(String equipmentId) =>
      _repo.listHistory(equipmentId);
  @override
  Future<void> move(
    String id, {
    required String toLocationId,
    required String toRoom,
    String? toClientId,
    String? notes,
  }) => _repo.move(
    id,
    toLocationId: toLocationId,
    toRoom: toRoom,
    toClientId: toClientId,
    notes: notes,
  );

  @override
  Future<void> replace(
    String id, {
    required Map<String, dynamic> newEquipment,
    String? notes,
  }) => _repo.replace(id, newEquipment: newEquipment, notes: notes);
}
