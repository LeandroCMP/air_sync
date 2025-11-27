abstract class SignupsRepository {
  Future<String> registerTenant({
    required String companyName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String document,
    int? billingDay,
    String? notes,
  });
}
