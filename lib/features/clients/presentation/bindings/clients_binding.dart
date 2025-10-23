import 'package:get/get.dart';

import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/delete_client_usecase.dart';
import '../../domain/usecases/get_client_detail_usecase.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/update_client_usecase.dart';
import '../controllers/client_detail_controller.dart';
import '../controllers/client_list_controller.dart';

class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientListController>(() => ClientListController(Get.find<GetClientsUseCase>(), Get.find<DeleteClientUseCase>()));
    Get.lazyPut<ClientDetailController>(() => ClientDetailController(
          Get.find<GetClientDetailUseCase>(),
          Get.find<CreateClientUseCase>(),
          Get.find<UpdateClientUseCase>(),
        ));
  }
}
