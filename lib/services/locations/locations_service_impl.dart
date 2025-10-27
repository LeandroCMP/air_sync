import 'package:air_sync/models/location_model.dart';
import 'package:air_sync/repositories/locations/locations_repository.dart';
import 'package:air_sync/services/locations/locations_service.dart';

class LocationsServiceImpl implements LocationsService {
  final LocationsRepository _repo;
  LocationsServiceImpl({required LocationsRepository repo}) : _repo = repo;

  @override
  Future<LocationModel> create({required String clientId, required String label, Map<String, String?> address = const {}, String? notes}) =>
      _repo.create(clientId: clientId, label: label, address: address, notes: notes);

  @override
  Future<List<LocationModel>> listByClient(String clientId) => _repo.listByClient(clientId);
}

