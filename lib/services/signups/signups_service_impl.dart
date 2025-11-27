import 'package:air_sync/repositories/signups/signups_repository.dart';
import 'package:air_sync/services/signups/signups_service.dart';

class SignupsServiceImpl implements SignupsService {
  SignupsServiceImpl({required SignupsRepository repository})
    : _repository = repository;

  final SignupsRepository _repository;

  @override
  Future<String> registerTenant({
    required String companyName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String document,
    int? billingDay,
    String? notes,
  }) {
    return _repository.registerTenant(
      companyName: companyName,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
      document: document,
      billingDay: billingDay,
      notes: notes,
    );
  }
}
