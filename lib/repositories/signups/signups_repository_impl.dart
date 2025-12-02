import 'package:air_sync/application/core/network/api_client.dart';
import 'package:air_sync/repositories/signups/signups_repository.dart';
import 'package:get/get.dart';

class SignupsRepositoryImpl implements SignupsRepository {
  SignupsRepositoryImpl() : _api = Get.find<ApiClient>();

  final ApiClient _api;

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
  }) async {
    final res = await _api.dio.post(
      '/v1/signups',
      data: {
        'companyName': companyName,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'document': document,
        'password': password,
        if (billingDay != null) 'billingDay': billingDay,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final data = res.data;
    if (data is Map && data['id'] != null) {
      return true;
    }
    return false;
  }
}
