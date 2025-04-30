import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/models/air_conditioner_model.dart';
import 'package:air_sync/models/residence_model.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/application/core/errors/client_failure.dart';
import 'package:uuid/uuid.dart';

class ClientController extends GetxController {
  final ClientService _clientService;
  final AuthServiceApplication _authServiceApplication;

  ClientController({
    required ClientService clientService,
    required AuthServiceApplication authServiceApplication,
  }) : _clientService = clientService,
       _authServiceApplication = authServiceApplication;

  @override
  void onInit() {
    registerClient(_authServiceApplication.user.value!.id);
    super.onInit();
  }

  @override
  void onReady() {
    getClients();
    super.onReady();
  }

  final formKey = GlobalKey<FormState>();

  // Form fields
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cpfOrCnpjController = TextEditingController();
  final birthDate = Rxn<DateTime>();

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final successMessage = RxnString();

  final RxList<ClientModel> clients = <ClientModel>[].obs;

  // Método para salvar cliente
  Future<void> registerClient(String userId) async {
    errorMessage.value = null;
    successMessage.value = null;

    //if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final client = ClientModel(
        id: '', // ID será gerado pelo Firebase
        userId: userId,
        name: 'nameController.text.trim()',
        phone: 'phoneController.text.trim()',
        cpfOrCnpj: 'cpfOrCnpjController.text.trim().isNotEmpty',
        /* ? cpfOrCnpjController.text.trim()
            : null,*/
        birthDate: DateTime.now(),
        residences: [
          ResidenceModel(id: Uuid().v1().toString(), name: 'Casa',airConditioners: [
            AirConditionerModel(id: Uuid().v1().toString(), room: 'Quarto Casal', model: 'fujitsu', btus: 12000)
          ])
        ]
      );

      await _clientService.registerClient(client);

      successMessage.value = 'Cliente cadastrado com sucesso!';
      clearForm();
    } on ClientFailure catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Erro inesperado ao cadastrar o cliente.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getClients() async {
    try {
      isLoading.value = true;

      final result = await _clientService.getClientsByUserId(
        _authServiceApplication.user.value!.id,
      );
      clients.assignAll(result);
      for (var element in clients) {
        print(element.name);
      }
    } catch (e) {
      // log, snackbar etc.
      Get.snackbar('Erro', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Método para resetar o formulário
  void clearForm() {
    nameController.clear();
    phoneController.clear();
    cpfOrCnpjController.clear();
    birthDate.value = null;
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    cpfOrCnpjController.dispose();
    super.onClose();
  }
}
