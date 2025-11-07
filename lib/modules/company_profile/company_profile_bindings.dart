import 'package:air_sync/modules/company_profile/company_profile_controller.dart';
import 'package:air_sync/repositories/company_profile/company_profile_repository.dart';
import 'package:air_sync/repositories/company_profile/company_profile_repository_impl.dart';
import 'package:air_sync/services/company_profile/company_profile_service.dart';
import 'package:air_sync/services/company_profile/company_profile_service_impl.dart';
import 'package:get/get.dart';

class CompanyProfileBindings implements Bindings {
  static void ensureServices() {
    if (!Get.isRegistered<CompanyProfileRepository>()) {
      Get.lazyPut<CompanyProfileRepository>(
        CompanyProfileRepositoryImpl.new,
        fenix: true,
      );
    }
    if (!Get.isRegistered<CompanyProfileService>()) {
      Get.lazyPut<CompanyProfileService>(
        () => CompanyProfileServiceImpl(repository: Get.find()),
        fenix: true,
      );
    }
  }

  @override
  void dependencies() {
    ensureServices();
    Get.put(
      CompanyProfileController(service: Get.find()),
    );
  }
}
