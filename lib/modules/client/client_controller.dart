import 'package:air_sync/application/auth/auth_service_application.dart';
import 'package:air_sync/application/ui/loader/loader_mixin.dart';
import 'package:air_sync/application/ui/messages/messages_mixin.dart';
import 'package:air_sync/services/client/client_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:air_sync/models/client_model.dart';
import 'package:air_sync/application/core/errors/client_failure.dart';

class ClientController extends GetxController with MessagesMixin, LoaderMixin {
  final ClientService _clientService;
  final AuthServiceApplication _authServiceApplication;

  ClientController({
    required ClientService clientService,
    required AuthServiceApplication authServiceApplication,
  })  : _clientService = clientService,
        _authServiceApplication = authServiceApplication;

  @override
  void onInit() {
    loaderListener(isLoading);
    messageListener(message);
    super.onInit();
  }

  @override
  void onReady() async {
    await getClients();
    super.onReady();
  }

  final formKey = GlobalKey<FormState>();

  // Form fields
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cpfOrCnpjController = TextEditingController();
  

  final isLoading = false.obs;
  final message = Rxn<MessageModel>();

  final RxList<ClientModel> clients = <ClientModel>[].obs;

  Future<void> registerClient() async {
    isLoading(true);
    try {
      final client = ClientModel(
        id: '',
        name: nameController.text.trim(),
        phones: [phoneController.text.trim()],
        emails: const [],
        docNumber: cpfOrCnpjController.text.trim().isNotEmpty
            ? cpfOrCnpjController.text.trim()
            : null,
        tags: const [],
        notes: null,
      );

      // Agora o service retorna o client com ID
      final savedClient = await _clientService.registerClient(client);

      clients.add(savedClient); // Adiciona com ID correto

      isLoading(false);
      await Future.delayed(const Duration(milliseconds: 300));
      Get.back(); // Fecha modal de cadastro

      message(
        MessageModel.success(
          title: 'Sucesso!',
          message: 'Cliente cadastrado com sucesso!',
        ),
      );

      clearForm();
    } on ClientFailure catch (e) {
      message(MessageModel.error(title: 'Erro!', message: e.message));
    } catch (_) {
      message(
        MessageModel.error(
          title: 'Erro!',
          message: 'Erro inesperado ao cadastrar o cliente.',
        ),
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> getClients() async {
    isLoading.value = true;
    try {
      final result = await _clientService.getClientsByUserId(
        _authServiceApplication.user.value!.id,
      );
      clients.assignAll(result);
    } catch (e) {
      Get.snackbar('Erro', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    nameController.clear();
    phoneController.clear();
    cpfOrCnpjController.clear();
    
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    cpfOrCnpjController.dispose();
    super.onClose();
  }
}

