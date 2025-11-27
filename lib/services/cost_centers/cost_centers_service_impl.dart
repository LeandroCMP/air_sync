import 'package:air_sync/models/cost_center_model.dart';
import 'package:air_sync/repositories/cost_centers/cost_centers_repository.dart';
import 'package:air_sync/services/cost_centers/cost_centers_service.dart';

class CostCentersServiceImpl implements CostCentersService {
  CostCentersServiceImpl({required CostCentersRepository repository})
    : _repository = repository;

  final CostCentersRepository _repository;

  @override
  Future<List<CostCenterModel>> list({bool includeInactive = true}) =>
      _repository.list(includeInactive: includeInactive);

  @override
  Future<CostCenterModel> create({
    required String name,
    String? code,
    String? description,
  }) => _repository.create(name: name, code: code, description: description);

  @override
  Future<CostCenterModel> update(
    String id, {
    String? name,
    String? code,
    String? description,
  }) => _repository.update(
    id,
    name: name,
    code: code,
    description: description,
  );

  @override
  Future<void> setActive(String id, bool active) =>
      _repository.setActive(id, active);
}
