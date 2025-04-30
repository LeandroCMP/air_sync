import 'package:air_sync/repositories/client/client_repository.dart';
import 'package:air_sync/repositories/client/client_repository_impl.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:air_sync/services/client/client_service_impl.dart';
import 'package:get/get.dart';
import './client_controller.dart';

class ClientBindings implements Bindings {
    @override
    void dependencies() {
     Get.lazyPut<ClientRepository>(
        () => ClientRepositoryImpl(authServiceApplication: Get.find()));
    Get.lazyPut<ClientService>(
      () => ClientServiceImpl(clientRepository: Get.find()),
    );
        Get.put(ClientController(
          clientService: Get.find(), 
          authServiceApplication: Get.find(),
        ));
    }
}