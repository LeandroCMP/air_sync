import 'package:air_sync/models/cost_center_model.dart';

abstract class CostCentersRepository {
  Future<List<CostCenterModel>> list({bool includeInactive = true});
  Future<CostCenterModel> create({
    required String name,
    String? code,
    String? description,
  });
  Future<CostCenterModel> update(
    String id, {
    String? name,
    String? code,
    String? description,
  });
  Future<void> setActive(String id, bool active);
}
