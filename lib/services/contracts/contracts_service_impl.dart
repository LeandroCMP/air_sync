import 'package:air_sync/models/contract_model.dart';
import 'package:air_sync/repositories/contracts/contracts_repository.dart';
import 'package:air_sync/services/contracts/contracts_service.dart';

class ContractsServiceImpl implements ContractsService {
  final ContractsRepository _repo;
  ContractsServiceImpl({required ContractsRepository repo}) : _repo = repo;

  @override
  Future<ContractModel> create({
    required String clientId,
    required String planName,
    required int intervalMonths,
    required int slaHours,
    required double priceMonthly,
    required List<String> equipmentIds,
    String? notes,
  }) =>
      _repo.create(
        clientId: clientId,
        planName: planName,
        intervalMonths: intervalMonths,
        slaHours: slaHours,
        priceMonthly: priceMonthly,
        equipmentIds: equipmentIds,
        notes: notes,
      );

  @override
  Future<List<ContractModel>> list() => _repo.list();
}


