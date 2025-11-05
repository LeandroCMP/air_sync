import 'package:air_sync/models/contract_model.dart';

abstract class ContractsRepository {
  Future<List<ContractModel>> list();
  Future<ContractModel> create({
    required String clientId,
    required String planName,
    required int intervalMonths,
    required int slaHours,
    required double priceMonthly,
    required List<String> equipmentIds,
    String? notes,
  });
}


