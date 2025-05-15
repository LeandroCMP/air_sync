import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/models/residence_model.dart';
import 'package:air_sync/modules/client/client_controller.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:search_cep/search_cep.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class ClientDetailsController extends GetxController
    with MessagesMixin, LoaderMixin {
  final ClientService _clientService;

  ClientDetailsController({
    required ClientService clientService,
  }) : _clientService = clientService;

  final Rx<ClientModel> client = (Get.arguments as ClientModel).obs;
  final RxInt totalAirConditioners = 0.obs;
  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  // Form controllers
  final residenceCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final complementCtrl = TextEditingController();
  final streetCtrl = TextEditingController();
  final zipCodeCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final nameAddress = TextEditingController();

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    _countAirConditioners();

    zipCodeCtrl.addListener(() {
      if (zipCodeCtrl.text.length == 9) {
        getZipCode();
      }
    });

    super.onInit();
  }

  Future<void> registerResidence() async {
    isLoading(true);
    try {
      final newResidence = ResidenceModel(
        id: const Uuid().v4(),
        name: residenceCtrl.text.trim(),
        number: numberCtrl.text.trim(),
        complement: complementCtrl.text.trim(),
        street: streetCtrl.text.trim(),
        zipCode: zipCodeCtrl.text.trim(),
        city: cityCtrl.text.trim(),
      );

      final updatedClient = client.value.copyWith(
        residences: [...client.value.residences, newResidence],
      );

      await _clientService.updateClient(updatedClient);
      client(updatedClient); // atualiza reatividade
      _countAirConditioners();
      clearForm();

      isLoading(false);
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back(); // Fecha modal de cadastro

      message(
        MessageModel.success(
          title: 'Sucesso',
          message: 'Endereço cadastrada com sucesso!',
        ),
      );
    } catch (e) {
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível registrar a residência.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  void _countAirConditioners() {
    totalAirConditioners.value = client.value.residences.fold(
      0,
      (sum, res) => sum + res.airConditioners.length,
    );
  }

  void clearForm() {
    residenceCtrl.clear();
    numberCtrl.clear();
    complementCtrl.clear();
    streetCtrl.clear();
    zipCodeCtrl.clear();
    cityCtrl.clear();
  }

  Future getZipCode() async {
    final zipCodeFormatted = zipCodeCtrl.text.replaceAll(RegExp(r'\D'), '');

    final viaCepSearchCep = ViaCepSearchCep();
    final infoCepJSON = await viaCepSearchCep.searchInfoByCep(
      cep: zipCodeFormatted,
    );
    if (infoCepJSON.isRight()) {
      infoCepJSON.map((result) {
        cityCtrl.text = result.localidade ?? "";
        streetCtrl.text = result.logradouro ?? "";
        complementCtrl.text = result.complemento ?? "";
      });
    } else {
      cityCtrl.clear();
      streetCtrl.clear();
      complementCtrl.clear();
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'CEP inválido ou inexistente!.',
        ),
      );
    }
  }

  backToClients() {
    final clientController = Get.find<ClientController>();
    final index = clientController.clients.indexWhere(
      (c) => c.id == client.value.id,
    );
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
      message(
        MessageModel.error(
          title: 'Erro',
          message: 'Não foi possível abrir o discador do telefone!',
        ),
      );
    }
  }

  @override
  void onClose() {
    residenceCtrl.dispose();
    numberCtrl.dispose();
    complementCtrl.dispose();
    streetCtrl.dispose();
    zipCodeCtrl.dispose();
    cityCtrl.dispose();
    super.onClose();
  }
}
