import 'package:air_sync/models/location_model.dart';

abstract class LocationsRepository {
  Future<List<LocationModel>> listByClient(String clientId);
  Future<LocationModel> create({
    required String clientId,
    required String label,
    Map<String, String?> address,
    String? notes,
  });
}

