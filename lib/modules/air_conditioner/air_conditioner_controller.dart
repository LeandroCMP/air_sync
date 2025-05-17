import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:air_sync/models/air_conditioner_model.dart';
import 'package:air_sync/models/residence_model.dart';

class AirConditionerController extends GetxController with MessagesMixin, LoaderMixin {
  final ClientService _clientService;
  final ResidenceModel residence;

  AirConditionerController({
    required ClientService clientService,
    required this.residence,
  }) : _clientService = clientService;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  final formKey = GlobalKey<FormState>();

  // Form fields for air conditioner
  final roomController = TextEditingController();
  final modelController = TextEditingController();
  final btusController = TextEditingController();

  RxList<AirConditionerModel> airConditioners = <AirConditionerModel>[].obs;

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  @override
  void onReady() {
    super.onReady();
    // Inicializa a lista de ar condicionados com os dados da residência
    airConditioners.assignAll(residence.airConditioners);
  }

  Future<void> registerAirConditioner() async {
    isLoading(true);
    try {
      final airConditioner = AirConditionerModel(
        id: '', // ID will be generated after save
        room: roomController.text.trim(),
        model: modelController.text.trim(),
        btus: int.parse(btusController.text.trim()),
      );

      // Add the new air conditioner to the list locally
      residence.airConditioners.add(airConditioner);
      airConditioners.add(airConditioner); // Update the local list

      // Save the updated residence with the new air conditioner to Firestore
      await _clientService.addNewAirConditioner(airConditioner, residence.id);

      isLoading(false);
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back(); // Close the modal after successful addition

      message(
        MessageModel.success(
          title: 'Sucesso!',
          message: 'Equipamento cadastrado com sucesso!',
        ),
      );

      clearForm();
    }catch (_) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: 'Erro inesperado ao cadastrar o equipamento.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  void clearForm() {
    roomController.clear();
    modelController.clear();
    btusController.clear();
  }

  @override
  void onClose() {
    roomController.dispose();
    modelController.dispose();
    btusController.dispose();
    super.onClose();
  }
}
