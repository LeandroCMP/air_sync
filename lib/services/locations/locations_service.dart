import 'package:air_sync/models/location_model.dart';

abstract class LocationsService {
  Future<List<LocationModel>> listByClient(String clientId);
  Future<LocationModel> create({
    required String clientId,
    required String label,
    Map<String, String?> address,
    String? notes,
  });

  Future<LocationModel> update({
    required String id,
    String? label,
    Map<String, String?> address,
    String? notes,
    bool includeNotes = false,
  });

  Future<void> delete(String id, {bool cascadeEquipments = false});
}
