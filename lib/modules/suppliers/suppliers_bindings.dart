import 'package:air_sync/repositories/suppliers/suppliers_repository.dart';
import 'package:air_sync/repositories/suppliers/suppliers_repository_impl.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:air_sync/services/suppliers/suppliers_service_impl.dart';
import 'package:get/get.dart';

import 'suppliers_controller.dart';

class SuppliersBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuppliersRepository>(() => SuppliersRepositoryImpl());
    Get.lazyPut<SuppliersService>(() => SuppliersServiceImpl(repo: Get.find()));
    Get.put(SuppliersController(service: Get.find()));
  }
}


