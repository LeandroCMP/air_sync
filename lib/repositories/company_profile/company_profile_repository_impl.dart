import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/whatsapp_status.dart';
import 'package:air_sync/repositories/company_profile/company_profile_repository.dart';
import 'package:air_sync/application/core/network/api_client.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

class CompanyProfileRepositoryImpl implements CompanyProfileRepository {
  CompanyProfileRepositoryImpl() : _dio = Get.find<ApiClient>().dio;

  final dio.Dio _dio;

  @override
  Future<CompanyProfileModel> fetchProfile() async {
    final res = await _dio.get('/v1/company/profile');
    return CompanyProfileModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<CompanyProfileModel> updateProfile(Map<String, dynamic> payload) async {
    final res = await _dio.put('/v1/company/profile', data: payload);
    return CompanyProfileModel.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<CompanyProfileExport> exportProfile() async {
    final res = await _dio.get('/v1/company/profile/export');
    return CompanyProfileExport.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<void> importProfile(Map<String, dynamic> payload) async {
    await _dio.post('/v1/company/profile/import', data: payload);
  }

  @override
  Future<WhatsAppStatus> fetchWhatsappStatus() async {
    final res = await _dio.get('/v1/whatsapp/status');
    return WhatsAppStatus.fromMap(Map<String, dynamic>.from(res.data));
  }

  @override
  Future<String> fetchWhatsappOnboardUrl() async {
    final res = await _dio.get('/v1/whatsapp/onboard');
    final data = res.data;
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    return data?.toString() ?? '';
  }

  @override
  Future<void> updateWhatsapp(Map<String, dynamic> payload) async {
    await _dio.put('/v1/company/whatsapp', data: payload);
  }

  @override
  Future<void> sendWhatsappTest(String phone) async {
    await updateWhatsapp({'testPhone': phone});
  }
}
