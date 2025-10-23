import 'package:get/get.dart';

import '../../domain/entities/client.dart';
import '../../domain/usecases/delete_client_usecase.dart';
import '../../domain/usecases/get_clients_usecase.dart';

class ClientListController extends GetxController {
  ClientListController(this._getClientsUseCase, this._deleteClientUseCase);

  final GetClientsUseCase _getClientsUseCase;
  final DeleteClientUseCase _deleteClientUseCase;

  final clients = <Client>[].obs;
  final isLoading = false.obs;
  final filter = ''.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final result = await _getClientsUseCase.call(text: filter.value.isEmpty ? null : filter.value);
    isLoading.value = false;
    result.fold(
      (failure) => error.value = failure.message,
      (data) {
        clients.assignAll(data);
        error.value = null;
      },
    );
  }

  Future<void> remove(String id) async {
    final result = await _deleteClientUseCase.call(id);
    result.fold(
      (failure) => Get.snackbar('Erro', failure.message),
      (_) {
        clients.removeWhere((element) => element.id == id);
        Get.snackbar('Sucesso', 'Cliente removido');
      },
    );
  }
}
