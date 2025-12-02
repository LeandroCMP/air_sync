import 'package:air_sync/repositories/signups/signups_repository.dart';
import 'package:air_sync/services/signups/signups_service.dart';

class SignupsServiceImpl implements SignupsService {
  SignupsServiceImpl({required SignupsRepository repository})
    : _repository = repository;

  final SignupsRepository _repository;

  @override
  Future<bool> registerTenant({
    required String companyName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String document,
    required String password,
    int? billingDay,
    String? notes,
  }) {
    return _repository.registerTenant(
      companyName: companyName,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
      document: document,
      password: password,
      billingDay: billingDay,
      notes: notes,
    );
  }
}
