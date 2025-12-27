import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/whatsapp_status.dart';

abstract class CompanyProfileService {
  Future<CompanyProfileModel> loadProfile();
  Future<CompanyProfileModel> saveProfile(CompanyProfileModel profile);
  Future<CompanyProfileExport> exportProfile();
  Future<void> importProfile(CompanyProfileModel profile);
  Future<WhatsAppStatus> fetchWhatsappStatus();
  Future<String> fetchWhatsappOnboardUrl();
  Future<void> disconnectWhatsapp();
  Future<void> sendWhatsappTest(String phone);
}
