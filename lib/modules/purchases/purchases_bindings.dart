import 'package:air_sync/repositories/purchases/purchases_repository.dart';
import 'package:air_sync/repositories/purchases/purchases_repository_impl.dart';
import 'package:air_sync/services/purchases/purchases_service.dart';
import 'package:air_sync/services/purchases/purchases_service_impl.dart';
import 'package:get/get.dart';
import 'package:air_sync/repositories/suppliers/suppliers_repository.dart';
import 'package:air_sync/repositories/suppliers/suppliers_repository_impl.dart';
import 'package:air_sync/services/suppliers/suppliers_service.dart';
import 'package:air_sync/services/suppliers/suppliers_service_impl.dart';
import 'package:air_sync/repositories/inventory/inventory_repository.dart';
import 'package:air_sync/repositories/inventory/inventory_repository_impl.dart';
import 'package:air_sync/services/inventory/inventory_service.dart';
import 'package:air_sync/services/inventory/inventory_service_impl.dart';
import 'package:air_sync/modules/inventory/inventory_controller.dart';
import 'package:air_sync/application/auth/auth_service_application.dart';

import 'purchases_controller.dart';

class PurchasesBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchasesRepository>(() => PurchasesRepositoryImpl());
    Get.lazyPut<PurchasesService>(() => PurchasesServiceImpl(repo: Get.find()));
    // Ensure SuppliersService is available for purchase listing (supplier name mapping)
    if (!Get.isRegistered<SuppliersRepository>()) {
      Get.lazyPut<SuppliersRepository>(() => SuppliersRepositoryImpl(), fenix: true);
    }
    if (!Get.isRegistered<SuppliersService>()) {
      Get.lazyPut<SuppliersService>(() => SuppliersServiceImpl(repo: Get.find()), fenix: true);
    }
    // Ensure InventoryService is available for item picker
    if (!Get.isRegistered<InventoryRepository>()) {
      Get.lazyPut<InventoryRepository>(() => InventoryRepositoryImpl(), fenix: true);
    }
    if (!Get.isRegistered<InventoryService>()) {
      Get.lazyPut<InventoryService>(() => InventoryServiceImpl(inventoryRepository: Get.find()), fenix: true);
    }
    // InventoryController para permitir cadastro direto de produto dentro da compra
    if (!Get.isRegistered<InventoryController>()) {
      Get.lazyPut<InventoryController>(
        () => InventoryController(authServiceApplication: Get.find<AuthServiceApplication>(), inventoryService: Get.find<InventoryService>()),
        fenix: true,
      );
    }
    Get.put(PurchasesController(service: Get.find()));
  }
}
