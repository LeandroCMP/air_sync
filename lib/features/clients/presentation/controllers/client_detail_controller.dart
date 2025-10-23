import 'package:get/get.dart';

import '../../domain/entities/client.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/get_client_detail_usecase.dart';
import '../../domain/usecases/update_client_usecase.dart';

class ClientDetailController extends GetxController {
  ClientDetailController(this._getDetailUseCase, this._createUseCase, this._updateUseCase);

  final GetClientDetailUseCase _getDetailUseCase;
  final CreateClientUseCase _createUseCase;
  final UpdateClientUseCase _updateUseCase;

  final client = Rxn<Client>();
  final isLoading = false.obs;
  final error = RxnString();

  Future<void> load(String id) async {
    isLoading.value = true;
    final result = await _getDetailUseCase.call(id);
    isLoading.value = false;
    result.fold(
      (failure) => error.value = failure.message,
      (data) {
        client.value = data;
        error.value = null;
      },
    );
  }

  Future<Client?> save({String? id, required Map<String, dynamic> payload}) async {
    isLoading.value = true;
    final result = id == null ? await _createUseCase.call(payload) : await _updateUseCase.call(id, payload);
    isLoading.value = false;
    return result.fold(
      (failure) {
        error.value = failure.message;
        Get.snackbar('Erro', failure.message);
        return null;
      },
      (data) {
        client.value = data;
        Get.snackbar('Sucesso', 'Dados salvos com sucesso');
        return data;
      },
    );
  }
}
