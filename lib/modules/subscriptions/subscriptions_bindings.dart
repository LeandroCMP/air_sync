import 'package:air_sync/modules/subscriptions/subscriptions_controller.dart';
import 'package:air_sync/services/subscriptions/subscriptions_service.dart';
import 'package:get/get.dart';

class SubscriptionsBindings implements Bindings {
  @override
  void dependencies() {
    // Instancia imediatamente para evitar falhas de resolução quando navegamos
    // diretamente para a tela de faturas em fluxos de conta suspensa.
    final controller = Get.put<SubscriptionsController>(
      SubscriptionsController(
        service: Get.find<SubscriptionsService>(),
        auth: Get.find(),
      ),
      permanent: true,
    );
    // Ajusta flag de restrição com base nos argumentos atuais da rota.
    final args = Get.arguments;
    if (args is Map && args['restricted'] == true) {
      controller.restricted.value = true;
    } else {
      controller.restricted.value = false;
    }
  }
}
