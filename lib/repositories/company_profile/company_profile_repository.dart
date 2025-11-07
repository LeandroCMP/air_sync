import 'package:air_sync/models/company_profile_model.dart';

abstract class CompanyProfileRepository {
  Future<CompanyProfileModel> fetchProfile();
  Future<CompanyProfileModel> updateProfile(Map<String, dynamic> payload);
  Future<CompanyProfileExport> exportProfile();
  Future<void> importProfile(Map<String, dynamic> payload);
}
