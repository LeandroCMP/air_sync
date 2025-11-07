import 'package:air_sync/models/company_profile_model.dart';

abstract class CompanyProfileService {
  Future<CompanyProfileModel> loadProfile();
  Future<CompanyProfileModel> saveProfile(CompanyProfileModel profile);
  Future<CompanyProfileExport> exportProfile();
  Future<void> importProfile(CompanyProfileModel profile);
}
