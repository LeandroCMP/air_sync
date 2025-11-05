import 'package:air_sync/repositories/contracts/contracts_repository.dart';
import 'package:air_sync/repositories/contracts/contracts_repository_impl.dart';
import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/repositories/client/client_repository_impl.dart';
import 'package:air_sync/repositories/equipments/equipments_repository.dart';
import 'package:air_sync/repositories/equipments/equipments_repository_impl.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/client/client_service_impl.dart';
import 'package:air_sync/services/contracts/contracts_service.dart';
import 'package:air_sync/services/contracts/contracts_service_impl.dart';
import 'package:get/get.dart';

import 'contracts_controller.dart';

class ContractsBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ContractsRepository>(() => ContractsRepositoryImpl());
    Get.lazyPut<ContractsService>(() => ContractsServiceImpl(repo: Get.find()));
    // Auxiliares para pickers
    Get.lazyPut<ClientRepository>(() => ClientRepositoryImpl(), fenix: true);
    Get.lazyPut<ClientService>(() => ClientServiceImpl(clientRepository: Get.find()), fenix: true);
    Get.lazyPut<EquipmentsRepository>(() => EquipmentsRepositoryImpl(), fenix: true);
    Get.put(ContractsController(service: Get.find()));
  }
}

