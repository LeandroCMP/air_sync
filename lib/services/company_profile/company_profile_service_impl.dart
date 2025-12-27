import 'package:air_sync/models/company_profile_model.dart';
import 'package:air_sync/models/whatsapp_status.dart';
import 'package:air_sync/repositories/company_profile/company_profile_repository.dart';
import 'package:air_sync/services/company_profile/company_profile_service.dart';

class CompanyProfileServiceImpl implements CompanyProfileService {
  CompanyProfileServiceImpl({required CompanyProfileRepository repository})
      : _repository = repository;

  final CompanyProfileRepository _repository;

  @override
  Future<CompanyProfileModel> loadProfile() => _repository.fetchProfile();

  @override
  Future<CompanyProfileModel> saveProfile(CompanyProfileModel profile) =>
      _repository.updateProfile(profile.toMap());

  @override
  Future<CompanyProfileExport> exportProfile() => _repository.exportProfile();

  @override
  Future<void> importProfile(CompanyProfileModel profile) =>
      _repository.importProfile({'profile': profile.toMap()});

  @override
  Future<WhatsAppStatus> fetchWhatsappStatus() =>
      _repository.fetchWhatsappStatus();

  @override
  Future<String> fetchWhatsappOnboardUrl() =>
      _repository.fetchWhatsappOnboardUrl();

  @override
  Future<void> disconnectWhatsapp() =>
      _repository.updateWhatsapp({'token': '', 'phoneId': ''});

  @override
  Future<void> sendWhatsappTest(String phone) =>
      _repository.sendWhatsappTest(phone);
}
