import 'package:air_sync/models/company_profile_model.dart';
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
}
