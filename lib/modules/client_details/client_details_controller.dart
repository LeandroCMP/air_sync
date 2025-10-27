import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/modules/client/client_controller.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientDetailsController extends GetxController with MessagesMixin, LoaderMixin {
  final ClientService _clientService;

  ClientDetailsController({required ClientService clientService}) : _clientService = clientService;

  final Rx<ClientModel> client = (Get.arguments as ClientModel).obs;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  void backToClients() {
    final clientController = Get.find<ClientController>();
    final index = clientController.clients.indexWhere((c) => c.id == client.value.id);
    if (index != -1) {
      clientController.clients[index] = client.value;
    }
    Get.back();
  }

  Future<void> launchDialer(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      message(MessageModel.error(title: 'Erro', message: 'Não foi possível abrir o discador do telefone!'));
    }
  }
}

