import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/services/locations/locations_service.dart';

class LocationsServiceImpl implements LocationsService {
  LocationsServiceImpl({required LocationsRepository repo}) : _repo = repo;

  final LocationsRepository _repo;

  @override
  Future<LocationModel> create({
    required String clientId,
    required String label,
    Map<String, String?> address = const {},
    String? notes,
  }) => _repo.create(
    clientId: clientId,
    label: label,
    address: address,
    notes: notes,
  );

  @override
  Future<List<LocationModel>> listByClient(String clientId) =>
      _repo.listByClient(clientId);

  @override
  Future<LocationModel> update({
    required String id,
    String? label,
    Map<String, String?> address = const {},
    String? notes,
    bool includeNotes = false,
  }) => _repo.update(
    id: id,
    label: label,
    address: address,
    notes: notes,
    includeNotes: includeNotes,
  );

  @override
  Future<void> delete(String id, {bool cascadeEquipments = false}) =>
      _repo.delete(id, cascadeEquipments: cascadeEquipments);
}
