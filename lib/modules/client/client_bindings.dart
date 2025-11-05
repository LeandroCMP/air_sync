import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/repositories/client/client_repository_impl.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/client/client_service_impl.dart';
import 'package:get/get.dart';

import 'client_controller.dart';

class ClientBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientRepository>(ClientRepositoryImpl.new, fenix: true);
    Get.lazyPut<ClientService>(
      () => ClientServiceImpl(clientRepository: Get.find()),
      fenix: true,
    );
    Get.put(ClientController(clientService: Get.find()));
  }
}
