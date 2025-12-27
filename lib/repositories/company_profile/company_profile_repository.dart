import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/whatsapp_status.dart';

abstract class CompanyProfileRepository {
  Future<CompanyProfileModel> fetchProfile();
  Future<CompanyProfileModel> updateProfile(Map<String, dynamic> payload);
  Future<CompanyProfileExport> exportProfile();
  Future<void> importProfile(Map<String, dynamic> payload);
  Future<WhatsAppStatus> fetchWhatsappStatus();
  Future<String> fetchWhatsappOnboardUrl();
  Future<void> updateWhatsapp(Map<String, dynamic> payload);
  Future<void> sendWhatsappTest(String phone);
}
