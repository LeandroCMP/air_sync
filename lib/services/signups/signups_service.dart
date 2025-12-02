abstract class SignupsService {
  Future<bool> registerTenant({
    required String companyName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String document,
    required String password,
    int? billingDay,
    String? notes,
  });
}
